use ap;
delimiter $$
drop procedure if exists payment_check $$
create procedure payment_check(in_invoice_id int, in_payment decimal(10, 2))
main:begin
    declare invoice decimal(10, 2);
    declare payment decimal(10, 2);
    declare credit decimal(10, 2);
    declare balance_due decimal(10, 2);
    declare available_payment decimal(10, 2);

    declare exit handler for not found 
    begin
        rollback;
        select 'invoice id not found.';
    end;
    declare exit handler for sqlexception
    begin
        rollback;
        select 'something went wrond.';
    end;

    -- validating inputs
    declare exit handler for sqlstate '45000'
    begin
        select 'invalid input invoice id.' as error_message;
    end;
    declare exit handler for sqlstate '45001'
    begin 
        select 'zero or negitive payment.' as error_message;
    end;
    if in_invoice_id <= 0 then
        signal sqlstate '45000'
        set MESSAGE_TEXT='invalid input invoice id';
    elseif in_payment <= 0 then
        signal sqlstate '45001'
        set MESSAGE_TEXT='invalid input payment.';
    end if;
    -- geting the invoice 

    start transaction;
    select 
        invoice_total, 
        credit_total, 
        payment_total 
    from invoices 
    where invoice_id = in_invoice_id
    for update 
    into invoice, credit, payment;
    set balance_due = invoice - credit - payment;
    if balance_due <= 0 then
        select "not enough balance." as message;
        rollback;
        leave main;
    elseif balance_due  < in_payment then
        select "payment overlap" as message;
        set available_payment = balance_due;
        select concat("the available payment is : ", balance_due) as message;
        update invoices set payment_total=payment_total+available_payment where invoice_id = in_invoice_id;

        select "available payment done." as message;
        commit;
        leave main;
    else
        update invoices set payment_total=payment_total+in_payment where invoice_id=in_invoice_id;
        select "payment done." as message;
    end if;
    commit;
end $$
delimiter ;

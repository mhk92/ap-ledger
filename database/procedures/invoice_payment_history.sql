use ap;
delimiter %%
drop procedure if exists invoice_payment_history %%
create procedure invoice_payment_history(in in_invoice_id)
sql security invoiker
reads sql data
main:begin
    -- goal: 
    --          1) take an invoice id
    --          2) validate
    --          3) check for existence
    --          4) give the success requests with payment amounts
    --  --  --
    -- variables
    declare message varchar(255) default '';
    declare invoice_count int default 0;

    -- conditions
    declare invalid_invoice_id condition for sqlstate '45000';
    declare invoice_not_found condition for sqlstate '45001';
    -- handlers
    declare exit handler for invalid_invoice_id
    begin
        resignal;
    end;
    declare exit handler for invoice_not_found
    begin
        resignal;
    end;
    -- validate
    if in_invoice_id < 0 then
        set message= 'invalid invoice id';
        signal invalid_invoice_id set MESSAGE_TEXT=message;
    end if;

    -- existence check
    select count(*) from invoices where invoice_id = in_invoice_id into invoice_count;
    if invoice_count = 0 then
        set message='invoice not found.';
        signal invoice_not_found set MESSAGE_TEXT=message;
    end if;
    -- main query
    select
        r.request_id,
        p.payment_id,
        r.completed_ad,
        p.payment_amount
    from payments as p
    inner join requests as r using (payment_id)
    where p.invoice_id = in_invoice_id;



end main %%
delimiter ;

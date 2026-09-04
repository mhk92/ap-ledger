use ap;
delimiter %%
drop procedure if exists payment_total_reconciliation %%
create procedure payment_total_reconciliation(in in_invoice_id int)
sql security invoker
reads sql data
main:begin
    -- goal:
    --      1) take an invoice id
    --      2) validate it
    --      3) check for existence in invoices and payments table
    --      3) compare payment_total in invoices with sumation payment_amount with same invoice id.
    --      4) I use common table expressins in this example.
    --  --
    -- variables
    declare message varchar(255) default '';
    declare invoice_count int default 0;
    declare payment_count int default 0;

    -- conditions
    declare null_invoice_id condition for sqlstate '45000';
    declare invalid_invoice_id condition for sqlstate '45001';
    declare no_invoice condition for sqlstate '45002';
    declare no_payment condition for sqlstate '45003';
    -- handlers
    declare exit handler for sqlexception
    begin 
        resignal;
    end;
    -- validation
    if in_invoice_id is null then
        set message='invoice id is required';
        signal null_invoice_id set MESSAGE_TEXT=message;
    elseif in_invoice_id <= 0 then
        set message='invalid invoice id';
        signal invalid_invoice_id set MESSAGE_TEXT=message;
    end if;
    -- existence check
    select count(*) from invoices where invoice_id = in_invoice_id into invoice_count;
    if invoice_count = 0 then
        set message='no invoice';
        signal no_invoice set MESSAGE_TEXT=message;
    end if;
    select count(*) from payments where invoice_id = in_invoice_id into payment_count;
    if payment_count = 0 then 
        set message='no payment with input invoice id';
        signal no_payment set MESSAGE_TEXT=message;
    end if;
    -- main query
    with SumPayment as (
        select 
            p.invoice_id as invoice_id,
            sum(p.payment_amount) as total_payment
        from payments as p
        where p.invoice_id = in_invoice_id 
        group by invoice_id
    ),
    InvoicePaymentTotal as (
        select 
            i.invoice_id as invoice_id,
            i.payment_total as payment_total
        from invoices as i
        where i.invoice_id = in_invoice_id )
    select 
        sp.invoice_id,
        sp.total_payment as 'sum payments',
        IPT.payment_total as 'total payment',
        case 
            when sp.total_payment != IPT.payment_total then 'suspicious'
        else 'good' end as 'status'
    from SumPayment as sp inner join InvoicePaymentTotal as IPT using (invoice_id);


end main %%
delimiter ;

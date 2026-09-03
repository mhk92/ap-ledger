use ap;
delimiter $$
drop procedure if exists payment_create $$
create procedure payment_create(in in_request_id varchar(36), 
                                in in_invoice_id int, 
                                in in_payment decimal(10, 2)
) sql security invoker  modifies sql data
main_body:begin
    -- valiables --
    declare message varchar(255) default "";
    declare current_total_payment decimal(10, 2);
    declare req_count int;
    declare failed_status boolean default false;
    declare error_message varchar(255);
    declare payment_id int;
    declare dup_request boolean default false;
    -- conditions --
    declare no_request_id condition for sqlstate '45000';
    declare invalid_invoice_id condition for sqlstate '45001';
    declare null_invoice_id condition for sqlstate '45002';
    declare invalid_payment condition for sqlstate '45003';
    declare null_payment condition for sqlstate '45004';
    

    -- handlers --
    declare exit handler for sqlexception
    begin
        resignal;
    end;
    declare exit handler for sqlstate '02000' -- not found
    begin
        resignal;
    end;

    -- input validation --
    if in_request_id is null then 
        set message='no request id.';
        signal no_request_id set MESSAGE_TEXT=message;
    end if;

    if in_invoice_id is null then
        set message='no invoice id';
        signal null_invoice_id set MESSAGE_TEXT=message;
    elseif in_invoice_id <= 0 then
        set message='invalid invoice id';
        signal invalid_invoice_id set MESSAGE_TEXT=message;
    end if;

    if in_payment is null then 
        set message='no payment amount';
        signal null_payment set MESSAGE_TEXT=message;
    elseif in_payment <= 0 then 
        set message='invalid payment amount';
        signal invalid_payment set MESSAGE_TEXT=message;
    end if;

    start transaction;
        -- request existance check --
        select count(*) from requests as r where r.request_id = in_request_id into req_count;
        -- invoice existance check --
        select payment_total from invoices where invoice_id = in_invoice_id for update into current_total_payment;
    
        if req_count > 0 then
            -- request_id already existed
            -- show the results
            select 
                r.request_id as 'request id', 
                r.received_at as 'request received',
                r.completed_at as 'request completed', 
                r.status as 'request status'
            from requests as r
            where r.request_id = in_request_id;
        else
            request_insert:begin
                declare duplicate_request condition for 1062;
                declare exit handler for duplicate_request
                begin
                    set dup_request = true;
                end;
                insert into requests (request_id, received_at, status) values (in_request_id, now(), 'processing');
            end request_insert;
            if dup_request then 
                select
                    r.request_id as 'requets id',
                    r.received_at as 'request received',
                    r.completed_at 'request completed',
                    r.status as 'request status'
                from requests as r where r.request_id = in_request_id;
                rollback;
                leave main_body;
            end if;

            savepoint s1;
            risky:begin
                declare exit handler for sqlexception
                begin
                    get diagnostics condition 1
                    error_message=MESSAGE_TEXT;
                    set failed_status=true;
                    rollback to savepoint s1;
                end;
                insert into payments (invoice_id, payment_amount, payment_date) values (in_invoice_id, in_payment, now());
                set payment_id= last_insert_id();
                update invoices as i set i.payment_total = i.payment_total + in_payment where i.invoice_id = in_invoice_id;
                update requests as r set r.status = 'success', completed_at = now() where r.request_id = in_request_id;
                select concat('payment with id: ',payment_id, ' and amount: ', in_payment, 'is done with success');
            end risky;
        end if;
        if failed_status then
            update requests as r set r.status='failed', completed_at=now() where r.request_id = in_request_id;
            select concat('request failed: ', error_message);
        end if;
        commit;
end $$
delimiter ;

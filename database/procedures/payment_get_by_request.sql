use ap;
delimiter $$
drop procedure if exists payment_get_by_request $$
create procedure payment_get_by_request(
    in in_req_id varchar(36),
    in in_status varchar(20) 
)
-- (null, null)
-- (in_req_id, null)
-- (in_req_id, in_status)
-- (null, in_status)
sql security invoker 
reads sql data
main_body:begin
    -- valiables
    declare message varchar(255);
    declare err_message varchar(255);
    declare req_count int;
    -- conditions
    declare inputs_null condition for sqlstate '45000';
    declare invalid_request condition for sqlstate '45001';
    declare invalid_status condition for sqlstate '45002';
    declare request_not_found condition for sqlstate '45003';
    -- handlers
    declare exit handler for sqlexception
    begin
        resignal;
    end;
    declare exit handler for request_not_found
    begin
        resignal; 
    end;
    -- validation
    if in_req_id is null and in_status is null then
        set message = 'request id or status is required.';
        signal inputs_null set MESSAGE_TEXT=message;
    elseif length(in_req_id) != 36 then
        set message='invalid request id';
        signal invalid_request set MESSAGE_TEXT=message;
    elseif in_status not in ('success', 'failed') then
        set message='invalid status. use success/failed';
        signal invalid_status set MESSAGE_TEXT=message;
    end if;
    -- request existance check
    if in_req_id is not null then
        select count(*) from requests where request_id = in_req_id into req_count;
        if req_count = 0 then
            set message='request not found';
            signal request_not_found set MESSAGE_TEXT=message;
        end if;
    end if;

    -- getting the results
    if in_req_id is not null and in_status is null then
        select
            coalesce(cast(r.payment_id as char), 'no payment') as 'payment id',
            r.received_at as 'request received',
            r.completed_at as 'request completed',
            r.status as 'request status'
        from requests as r where r.request_id = in_req_id;
    elseif in_req_id is not null and in_status is not null then
        select
            coalesce(cast(r.payment_id as char), 'no payment') as 'payment id',
            r.received_at as 'request received',
            r.completed_at as 'request completed'
        from requests as r
        where r.request_id = in_req_id and r.status = in_status;
    elseif in_req_id is null and in_status is not null then 
        select
            r.request_id as 'request id',
            coalesce(cast(r.payment_id as char), 'no payment') as 'payment id',
            r.received_at as 'request received',
            r.completed_at as 'request completed'
        from requests as r
        where r.status = in_status;
    end if;
end main_body $$
delimiter ;

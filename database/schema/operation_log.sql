create table operations_log (
  log_id int unsigned not null auto_increment,
  request_id varchar(36),
  payment_id int unsigned,
  invoice_id int,
  occurred_at timestamp not null,
  sql_state varchar(5),
  mysql_err varchar(4),
  message varchar(255),
  status enum('SUCCESS', 'FAILED'),
  event_type enum('WARNING', 'INFO', 'ERROR'),
  operation enum('PAYMENT_CREATE', 
                  'INVOICE_RECONCILE', 'REQUEST_RETRIED',
                  'REQUEST_FAILED', 'SUSPICIOUS_INVOICE'),
  constraint pk_log primary key (log_id),
  constraint fk_request_log foreign key (request_id) references requests (request_id),
  constraint fk_payment_log foreign key (payment_id) references payments (payment_id),
  constraint fk_invoice_log foreign key (invoice_id) references invoices (invoice_id)
);

create table requests (
  request_id varchar(36) not null,
  payment_id int unsigned ,
  received_at datetime not null,
  completed_at datetime ,
  status enum('success', 'failed', 'processing'),
  constraint pk_request primary key (request_id),
  constraint fk_payment foreign key (payment_id) references payments (payment_id)
);

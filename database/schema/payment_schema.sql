create table payments (
  payment_id int unsigned not null,
  invoice_id int not null,
  payment_amount decimal(10, 2) check(payment_amount > 0),
  payment_date datetime not null,
  constraint pk_payment primary key (payment_id),
  constraint fk_invoice foreign key (invoice_id) references invoices (invoice_id) on delete restrict on update cascade
);

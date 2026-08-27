select
    v.vendor_id as id,
    v.vendor_name as 'vendor name',
    count(i.invoice_id) as 'number of invoices',
    sum(i.invoice_total) as 'total invoice',
    sum(i.payment_total) as 'total payment',
    sum(i.credit_total) as 'total credit',
    sum(i.invoice_total - i.credit_total - i.payment_total) as 'outstanding'
from vendors as v inner join invoices as i using (vendor_id)
where i.invoice_total - i.credit_total - i.payment_total > 0
group by v.vendor_id 
order by sum(i.invoice_total - i.credit_total - i.payment_total) desc;

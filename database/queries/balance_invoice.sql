select
    i.invoice_id as 'invoice id',
    v.vendor_name as 'vendor name',
    (i.invoice_total - i.credit_total - i.payment_total) as 'balance'

from invoices as i inner join vendors as v using (vendor_id)
where  (i.invoice_total - i.credit_total - i.payment_total) > 0
order by balance desc;

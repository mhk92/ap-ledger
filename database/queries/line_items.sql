select
    gl.account_number,
    gl.account_description,
    sum(il.line_item_amount) as 'max amount'
from general_ledger_accounts as gl 
inner join invoice_line_items as il using (account_number)
group by gl.account_number, gl.account_description
order by sum(il.line_item_amount) desc;

ALTER PROCEDURE [dbo].[RepReceiptv3]
	@refno char(30),
	@sno varchar(20),
	@poscode char(10),
	@CashierNo char(10)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Select
tbl.transactionDate as [Trxn Date],
tbl.RefNo, 
tbl.Cardtype, 
tbl.Cardname as [Card Holder], 
tbl.cardno as [Card No.],  
SUM(tbl.Principal) as AmountDue,
SUM(tbl.Surcharge) as Surcharge,
SUM(tbl.Interest) as Interest,
SUM(tbl.Membership) as Membership,
SUM(tbl.Replacement) as Replacement,
SUM(tbl.Renewal) as Renewal,
SUM(tbl.[Filing Fee]) as [Filing Fee],
SUM(tbl.Other) as Other,
SUM(tbl.Membership) as Membership,
--SUM(tbl.Amount) as Total,
tbl.Remarks,
(Select Top 1 DueDate from dbo.tblPayments where RefNo = tbl.RefNo)as DueDate,
(Select SUM(Discounts) from dbo.tblPayments where RefNo = tbl.RefNo)as Discount,
SUM(Isnull(tbl.Amount,0)) - Isnull((Select SUM(Discounts) from dbo.tblPayments where RefNo = tbl.RefNo),0) as Total,
SUM(Isnull(tbl.Surcharge,0)) + SUM(Isnull(tbl.Interest,0)) as TotalPenalty,
SUM(Isnull(tbl.Principal,0)) + SUM(Isnull(tbl.Surcharge,0)) + SUM(Isnull(tbl.Interest,0)) as CreditToAcct
from
(Select a.transactionDate, 
a.RefNo, 
d.Cardtype, 
d.Cardname, 
d.cardno, 
Null as Principal,
Null as Surcharge,
Null as Interest, 
Case when c.transtypeid = 3 then b.Amount End as Membership,
Case when c.transtypeid = 7 then b.Amount End as Replacement,
Case when c.transtypeid = 8 then b.Amount End as Renewal,
Case when c.transtypeid = 10 then b.Amount End as [Filing Fee],
Case when c.TransTypeID not in (3,8,7,10) or c.TransTypeID = 12 then b.Amount End as Other,
--Case when c.TransTypeID = 11 then b.Amount End as Other,
e.Description as [TransType], 
b.Amount,
a.Remarks 
from dbo.tblRFIDLedger a 
inner join dbo.tblPaymentDetails b on a.RefNo = b.RefNo and a.serialno = b.sno 
inner join dbo.tblRFIDLedger c on b.RefID = c.EntryNo and c.transtypeid not in (2,5) 
inner join dbo.tblRFIDSerials d on a.SerialNo = d.Sno 
inner join dbo.tblTransType e on e.TransTypeID = c.TransTypeID
where a.TransTypeID = 11
and a.refno = @refno
and a.serialno = @sno
and Isnull(a.POSCode,'') = @poscode
and Isnull(a.CashierNo,'') = @cashierno

union all

Select a.transactionDate, 
a.RefNo, 
d.Cardtype, 
d.Cardname, 
d.cardno, 
Case when b.DeductionType = 'Principal' then b.Amount End as Principal,
Case when b.DeductionType = 'Surcharge' then b.Amount End as Surcharge,
Case when b.DeductionType = 'Interest' then b.Amount End as Interest, 
Null as Membership,
Null as Replacement,
Null as Renewal,
Null as [Filing Fee],
Null as Other,
b.DeductionType as [TransType], 
b.Amount,
a.Remarks 
from dbo.tblRFIDLedger a 
inner join
dbo.tblPaymentDetails b on a.RefNo = b.RefNo and a.serialno = b.sno 
inner join
--dbo.tblRFIDLedger c on b.RefID = c.EntryNo and c.transtypeid in (2,5) inner join
dbo.tblRFIDSerials d on a.SerialNo = d.Sno 
--inner join
--dbo.tblTransType e on e.TransTypeID = c.TransTypeID
where a.TransTypeID = 2 and b.DeductionType <> 'Fees'
and a.refno = @refno
and a.serialno = @sno
and Isnull(a.POSCode,'') = @poscode
and Isnull(a.CashierNo,'') = @cashierno
) tbl
Group by tbl.transactionDate,
tbl.RefNo, 
tbl.Cardtype, 
tbl.Cardname, 
tbl.cardno,
 tbl.Remarks
--,
--tbl.Remarks 
Order by tbl.transactionDate desc
	
END
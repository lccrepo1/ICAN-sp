ALTER PROCEDURE [dbo].[RepTCCollectionDtlsv4XLS]
	@DateFrom as datetime,
	@DateTo as datetime
AS
BEGIN
	SET NOCOUNT ON;
	
		Select TT1.*,
		Case when TT1.[Action] = 'PAY' then Isnull(TT2.[Cash Collected],TT1.[Total]) else Isnull(TT2.[Cash Collected],TT1.[Total]) * -1 end as [CashCollected],  
		Case when TT1.[Action] = 'PAY' then Isnull(TT2.[Total Payment],TT1.[Total]) else Isnull(TT2.[Total Payment],TT1.[Total]) * -1 end as [TotalPayment], 

		Case when TT1.[Action] = 'PAY' then IsNull(TT2.Discount,0.00) else IsNull(TT2.Discount * -1,0.00) end as [Discount]
		from
		(Select 
		T1.[Trxn Date] as [TrxnDate], T1.Cashier, T1.Serial, T1.[Cardholder], T1.RefNo, T1.[Action],
		Case when T1.[Action] = 'PAY' then IsNull(sum(Purchases),0.00) else IsNull(sum(Purchases) * -1, 0.00) end as Purchases,
		Case when T1.[Action] = 'PAY' then IsNull(Sum([Pen&Int.]),0.00) else IsNull(Sum([Pen&Int.]) * -1, 0.00) end as [PenAndInt],
		Case when T1.[Action] = 'PAY' then IsNull(Sum([MembershipFee]), 0.00) else IsNull(Sum([MembershipFee]) * -1,0.00) end as [MembershipFee],
		Case when T1.[Action] = 'PAY' then IsNull(Sum([ReplacementFee]),0.00) else IsNull(Sum([ReplacementFee]) * -1, 0.00) end as [ReplacementFee],
		Case when T1.[Action] = 'PAY' then IsNull(Sum([AnnualFee]),0.00) else IsNull(Sum([AnnualFee]) * -1,0.00) end as [AnnualFee],
		Case when T1.[Action] = 'PAY' then IsNull(Sum([FilingFee]),0.00) else IsNull(Sum([FilingFee]) * -1, 0.00) end as [FilingFee],
		Sum([Total]) as [Total]
		from
		(Select b.TransactionDate as [Trxn Date], e.Name as Cashier, c.Sno as Serial, c.CardName as [Cardholder], a.RefNo,
		Case when a.DeductionType = 'Principal' then a.Amount else Null end as Purchases,
		Case when a.DeductionType = 'Surcharge' or a.DeductionType = 'Interest' then a.Amount else Null end as [Pen&Int.],
		Case when a.DeductionType = 'Fees' and g.TransTypeID = 3 then a.Amount else Null end as [MembershipFee],
		Case when a.DeductionType = 'Fees' and g.TransTypeID = 7 then a.Amount else Null end as [ReplacementFee],
		Case when a.DeductionType = 'Fees' and g.TransTypeID = 8 then a.Amount else Null end as [AnnualFee],
		Case when a.DeductionType = 'Fees' and g.TransTypeID = 10 then a.Amount else Null end as [FilingFee],
		a.Amount as Total,
		isnull(d.[Action],'PAY') as [Action]
		from tblPaymentDetails a inner join 
		tblRFIDLedger b on a.RefNo = b.RefNo and a.SNO = b.SerialNo and b.Transtypeid in (2,11) left join
		tblRFIDSerials c on a.sno = c.sno left join
	sAuditTrail d on a.RefNo = d.RecordID and (d.[Action] = 'PAY')	left join
		tblUser e on d.UserId = e.UserID left join
		dbo.tblTransPayMode f on f.EntryNo = b.EntryNo left join
		tblRFIDLedger g on g.EntryNo = a.RefID and a.DeductionType = 'Fees'
		where convert(char(10),b.TransactionDate,101) between @DateFrom and @DateTo
		and a.Amount <> 0
		and (f.PaymentMode is null or f.PaymentMode = 'Cash')
		and b.remarks not like '%waived%') T1
		Group by T1.[Trxn Date], T1.Cashier, T1.Serial, T1.[Cardholder], T1.RefNo, T1.[Action]) TT1 left join
		(Select a.SNO, a.RefNo, SUM(Isnull(a.Collection,0)) as [Cash Collected], 
		SUM(Isnull(a.Discounts,0)) as [Discount], SUM(Isnull(a.Collection,0)) +  SUM(Isnull(a.Discounts,0)) as [Total Payment]
		from tblPayments a Group by a.Sno, a.RefNo ) TT2 on TT1.Serial = TT2.Sno and TT1.RefNo = TT2.RefNo
	ORDER BY TT1.Cashier
END
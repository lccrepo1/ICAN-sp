ALTER PROCEDURE [dbo].[RepTCCollectionSum2XLS]

	@DateFrom as datetime,
	@DateTo as datetime
AS
BEGIN

	SET NOCOUNT ON;
			
Select 
	 tbl.POSCode
	,tbl.Cashier
	,COUNT(tbl.Serial) as [TrxnNum]
	,ISNULL(SUM(tbl.[Total Payment]),0.00) as [TotalPayment]
	,ISNULL(SUM(tbl.Discount),0.00) as Discount
	,ISNULL(SUM(tbl.[Cash Collected]),0.00) as [CashCollected]
	,ISNULL(SUM(tbl.Purchases),0.00) as Purchases
	,ISNULL(SUM(tbl.[Pen.&Int.]),0.00) as [PenAndInt]
	,ISNULL(SUM(tbl.[Membership Fee]),0.00) as [MembershipFee]
	,ISNULL(SUM(tbl.[Replacement Fee]),0.00) as [ReplacementFee]
	,ISNULL(SUM(tbl.[Annual Fee]),0.00) as [AnnualFee]
	,ISNULL(SUM(tbl.[Filing Fee]),0.00) as [FilingFee]
from
(
		Select 
			TT1.*,
			Case when TT1.[Action] = 'PAY' then Isnull(TT2.[Cash Collected],TT1.[Total]) else Isnull(TT2.[Cash Collected],TT1.[Total]) * -1 end 
				as [Cash Collected],  
			Case when TT1.[Action] = 'PAY' then Isnull(TT2.[Total Payment],TT1.[Total]) else Isnull(TT2.[Total Payment],TT1.[Total]) * -1 end 
				as [Total Payment],
			Case when TT1.[Action] = 'PAY' then TT2.Discount else TT2.Discount * -1 end 
				as [Discount]
		from
		(Select 
			T1.[Trxn Date], T1.POSCode, T1.Cashier, T1.Serial, T1.[Cardholder], T1.RefNo, T1.[Action],
			Case when T1.[Action] = 'PAY' then sum(Purchases) else sum(Purchases) * -1 end 
				as Purchases,
			Case when T1.[Action] = 'PAY' then Sum([Pen&Int.]) else Sum([Pen&Int.]) * -1 end 
				as [Pen.&Int.],
			Case when T1.[Action] = 'PAY' then Sum([Membership Fee]) else Sum([Membership Fee]) * -1 end 
				as [Membership Fee],
			Case when T1.[Action] = 'PAY' then Sum([Replacement Fee]) else Sum([Replacement Fee]) * -1 end 	
				as [Replacement Fee],
			Case when T1.[Action] = 'PAY' then Sum([Annual Fee]) else Sum([Annual Fee]) * -1 end 
				as [Annual Fee],
			Case when T1.[Action] = 'PAY' then Sum([Filing Fee]) else Sum([Filing Fee]) * -1 end 
				as [Filing Fee],
			Sum([Total]) as [Total]
		 from
			(Select 
				 b.TransactionDate as [Trxn Date]
				,b.POSCode
				,e.Name as Cashier
				,c.Sno as Serial
				,c.CardName as [Cardholder]
				,a.RefNo
				,Case when a.DeductionType = 'Principal' then a.Amount else Null end 
						as Purchases
				,Case when a.DeductionType = 'Surcharge' or a.DeductionType = 'Interest' then a.Amount else Null end 
						as [Pen&Int.]
				,Case when a.DeductionType = 'Fees' and g.TransTypeID = 3 and SUBSTRING(g.remarks,0,15) = 'membership fee' then a.Amount else Null end 
						as [Membership Fee]
				,Case when a.DeductionType = 'Fees' and (g.TransTypeID = 7 or g.TransTypeID = 8) then a.Amount else Null end 
						as [Replacement Fee]
				,Case when a.DeductionType = 'Fees' and g.TransTypeID = 3 and SUBSTRING(g.remarks,0,12) = 'renewal fee' then a.Amount else Null end 
						as [Annual Fee]
				,Case when a.DeductionType = 'Fees' and g.TransTypeID = 10 then a.Amount else Null end 
						as [Filing Fee]
				,a.Amount as Total
				,isnull(d.[Action],'PAY') as [Action]
			 from 
				tblPaymentDetails a inner join 
				tblRFIDLedger b on a.RefNo = b.RefNo and a.SNO = b.SerialNo and b.Transtypeid in (2,11) inner join
				tblRFIDSerials c on a.sno = c.sno left join
				sAuditTrail d on a.RefNo = d.RecordID and (d.[Action] = 'PAY' or d.[Action] = 'REVERSE') left join
				tblUser e on d.UserId = e.UserID left join
				dbo.tblTransPayMode f on f.EntryNo = b.EntryNo left join
				tblRFIDLedger g on g.EntryNo = a.RefID and a.DeductionType = 'Fees'
			where 
				convert(char(10),b.TransactionDate,101) between @DateFrom and @DateTo
				and a.Amount <> 0
				and (f.PaymentMode is null or f.PaymentMode = 'Cash')
				and b.remarks not like '%waived%'
			) T1
			Group by 
				T1.[Trxn Date], 
				T1.POSCode,
				T1.Cashier, 
				T1.Serial, 
				T1.[Cardholder], 
				T1.RefNo, 
				T1.[Action]
		) TT1 
		left join
		(Select 
				a.SNO, a.RefNo, SUM(Isnull(a.Collection,0)) as [Cash Collected], 
				SUM(Isnull(a.Discounts,0)) as [Discount], SUM(Isnull(a.Collection,0)) +  SUM(Isnull(a.Discounts,0)) as [Total Payment]
			 from tblPayments a Group by a.Sno, a.RefNo 
		 ) TT2 on TT1.Serial = TT2.Sno and TT1.RefNo = TT2.RefNo 
) Tbl	
Group By tbl.POSCode,tbl.Cashier
ORDER BY tbl.POSCode
END
ALTER PROCEDURE [dbo].[RepAgingReportXLS]
	@cardtype nchar(10),
	@from datetime,
	@to datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

Declare @TmpTbl TABLE  (
	   [CardNo] [varchar](50),
	   [CardName] [char](100),
	   [BegBal] [decimal](18, 2) NULL,
	   [Addition] [decimal](18, 2) NULL,
	   [Penalties] [decimal](18, 2) NULL,
	   [Collection] [decimal](18, 2) NULL,
	   [PPD] [decimal](18, 2) NULL,
	   [Current] [decimal](18, 2) NULL,
	   [1 to 30 Days] [decimal](18, 2) NULL,
	   [31 to 60 Days] [decimal](18, 2) NULL,
	   [61 to 90 Days] [decimal](18, 2) NULL,
	   [91 to 120 Days] [decimal](18, 2) NULL,
	   [Over 120 Days] [decimal](18, 2) NULL
	)

-- Get BegBal --
Insert into @TmpTbl ([CardNo],[CardName],[BegBal])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))* -1 as [BegBal]
from dbo.tblRFIDLedger a inner join
 dbo.tblRFIDSerials b on a.SerialNo = b.Sno 
where (convert(varchar(10),a.transactionDate,101) < @from) 
and b.Cardtype = @cardtype 
and (a.TransTypeID = 1 or a.TransTypeID = 2 or a.TransTypeID = 5 or a.TransTypeID = 9
)
Group by b.cardno , b.Cardname
Union All

Select b.cardno, b.Cardname,  
Sum(Isnull(c.Amount,0))-Sum(Isnull(a.Amount,0)) as [BegBal] 
from tblPenalties a inner join
tblRFIDSerials b on a.sno = b.sno inner join
(Select sum(Amount) as Amount, RefID from tblPaymentDetails 
	where (convert(varchar(10),TransDate,101) < @from) 
	and (DeductionType = 'Interest' or DeductionType = 'Surcharge')
 Group by RefID) c on a.PenaltyID = c.RefID 
where (convert(varchar(10),a.PenaltyDate,101) < @from) 
and b.Cardtype = @cardtype 
Group by b.cardno , b.Cardname


-- Get Addition --
Insert into @TmpTbl (CardNo , CardName , Addition)	
Select  b.cardno, b.Cardname, Sum(a.Amount)*-1 as Addition 
from dbo.tblRFIDLedger a inner join
dbo.tblRFIDSerials b on a.SerialNo = b.Sno 
where (convert(varchar(10),a.transactionDate,101) between @from and @to)
and b.Cardtype = @cardtype and a.TransTypeID = 1
Group by b.Cardno, b.Cardname

-- Get Penalties --
Insert into @TmpTbl (CardNo , CardName , Penalties)
--Group by b.cardno , b.Cardname

Select b.cardno , b.Cardname,
Sum(Isnull(a.amount,0)) as Penalty 
from dbo.tblPaymentDetails a inner join
dbo.tblRFIDSerials b on a.sno = b.Sno
where (a.deductiontype = 'Interest' or a.deductiontype = 'Surcharge')  
and (convert(char(10), a.TransDate, 101) between @from and @to) 
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname
-- Get Collection --
Insert into @TmpTbl (CardNo , CardName , [Collection])	
Select  b.cardno, b.Cardname, Sum(a.[Collection]) as [Collection] 
from dbo.tblPayments a inner join
dbo.tblRFIDSerials b on a.Sno = b.Sno 
where (convert(varchar(10),a.TransactionDate,101) between @from and @to)
and b.Cardtype = @cardtype
Group by b.Cardno, b.Cardname

-- Get PPD --
Insert into @TmpTbl (CardNo , CardName , PPD )
Select  b.cardno, b.Cardname, Sum(a.Discounts) as [PPD] 
from dbo.tblPayments a inner join
dbo.tblRFIDSerials b on a.Sno = b.Sno 
where (convert(varchar(10),a.TransactionDate,101) between @from and @to)
and b.Cardtype = @cardtype
Group by b.Cardno, b.Cardname

-- Get Current --
Insert into @TmpTbl ([CardNo],[CardName],[Current])
Select b.cardno , b.Cardname,
Sum(Isnull(a.Amount,0)) - Sum(Isnull(c.TAmount,0)) as [Current]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) <=0 
and b.Cardtype = @cardtype and convert(char(10), a.trandate, 101) <=@to
Group by b.cardno , b.Cardname

-- Get 1 to 30 --
Insert into @TmpTbl ([CardNo],[CardName],[1 to 30 Days])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))-
Sum(Isnull(c.TAmount,0)) as [1 to 30 Days]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) between 1 and 30
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname

-- Get 31 to 60 --
Insert into @TmpTbl ([CardNo],[CardName],[31 to 60 Days])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))-
Sum(Isnull(c.TAmount,0)) as [31 to 60 Days]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) between 31 and 60
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname

-- Get 61 to 90 --
Insert into @TmpTbl ([CardNo],[CardName],[61 to 90 Days])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))-
Sum(Isnull(c.TAmount,0)) as [61 to 90 Days]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) between 61 and 90
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname

-- Get 91 to 120 --
Insert into @TmpTbl ([CardNo],[CardName],[91 to 120 Days])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))-
Sum(Isnull(c.TAmount,0)) as [91 to 120 Days]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) between 91 and 120
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname

-- Get over 120 --
Insert into @TmpTbl ([CardNo],[CardName],[Over 120 Days])
Select b.cardno , b.Cardname ,
Sum(Isnull(a.Amount,0))-
Sum(Isnull(c.TAmount,0)) as [Over 120 Days]
from dbo.tblDuedates a inner join
 dbo.tblRFIDSerials b on a.sno = b.Sno left join
 (Select sum(Isnull(amount,0)) as TAmount, refID from dbo.tblPaymentDetails aa where deductiontype = 'Principal' and convert(char(10), aa.TransDate, 101) <=@to Group by refID) c on c.refid = a.DueID
where DATEDIFF(DD,a.[DueDate],@from) > 120
and b.Cardtype = @cardtype
Group by b.cardno , b.Cardname


-- CHAD 092518 Add Address
Select 
RTRIM(LTRIM(A.CardNo)) as [C_CardNo], 
RTRIM(LTRIM(A.CardName)) as [C_CardName],
COALESCE(RTRIM(LTRIM(REPLACE(REPLACE(C.ResidentAddress, CHAR(13), ''), CHAR(10), ' '))),'') AS [C_Address],
RTRIM(LTRIM(C.CompanyName)) as [C_CompanyName],
RTRIM(LTRIM(C.Occupation)) as [C_Position],
COALESCE(RTRIM(LTRIM(REPLACE(REPLACE(C.BusinessAddress, CHAR(13), ''), CHAR(10), ' '))),'') AS [C_CompanyAddress],
SUM(Isnull(BegBal,0)) as [N_BegBal],
SUM(Isnull([Addition],0)) as [N_Addition],
SUM(Isnull([Penalties],0)) as [N_Penalties],
SUM(Isnull([Collection],0)) as [N_Collection],
SUM(Isnull(PPD,0)) as [N_PPD],
(SUM(Isnull(BegBal,0)) + SUM(Isnull([Addition],0)) + SUM(Isnull([Penalties],0)))-
(SUM(Isnull([Collection],0)) + SUM(Isnull(PPD,0))) as [N_EndBal],
SUM(Isnull([Current],0)) as [N_Current],
SUM(Isnull([1 to 30 Days],0)) as [N_1 to 30 Days],
SUM(Isnull([31 to 60 Days],0)) as [N_31 to 60 Days],
SUM(Isnull([61 to 90 Days],0)) as [N_61 to 90 Days],
SUM(Isnull([91 to 120 Days],0)) as [N_91 to 120 Days],
SUM(Isnull([Over 120 Days],0)) as [N_Over 120 Days]
from @TmpTbl A LEFT JOIN tblRFIDSerials B ON A.CardNo = B.cardno
							 LEFT JOIN tblCustomer C ON B.CustomerID = C.CustomerID 	
Group by A.CardNo , A.CardName, C.ResidentAddress, C.CompanyName, C.Occupation, C.BusinessAddress

END
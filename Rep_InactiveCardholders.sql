ALTER PROCEDURE [dbo].[Rep_InactiveCardholders]
@gDate as datetime,
@CardType as varchar(50)
AS
BEGIN

SELECT
	a.Cardtype as [Card Type],
	RTRIM(LTRIM( A.Cardname )) AS [Card Name],
	A.cardno 	AS [Card Number],
	B.PhoneNo AS [Contact Number],
	b.ResidentAddress as [Resident Address],
	B.CompanyName as [Company Name],
	c.CMAddress as [Company Address],
	A.initialload AS [Limit],
	--CAST(A.expirydate AS DATE) 'Expiration Date',
	D.transactionDate AS [Last Purchase],
	A.status 	AS [Status]
	--E.transactionDate1 AS 'Last Payment'
FROM
	tblRFIDSerials A
LEFT JOIN tblCustomer B ON A.CustomerID = B.CustomerID 
LEFT JOIN tblCustomer2 C ON A.CustomerID = C.CustomerID
LEFT JOIN tblCardType F ON A.Cardtype = F.CardType
LEFT JOIN (SELECT
							SerialNo,
							MAX(transactionDate) AS transactionDate
						FROM tblRFIDLedger
						WHERE Remarks Like '%Purchase%'
							OR Remarks Like '%Purchase%' AND transactionDate IS NULL
						GROUP BY SerialNo
						HAVING  MAX(transactionDate) <= @gDate) D
	ON A.Sno = D.SerialNo
	LEFT JOIN (SELECT
							SerialNo,
						 max(transactionDate) AS transactionDate1
						FROM tblRFIDLedger
						WHERE Remarks Like '%Payment%'
						GROUP BY SerialNo) E
		ON A.Sno = E.SerialNo
	
WHERE D.transactionDate IS NOT NULL and F.CardType = @CardType

ORDER BY
	Cardname

END
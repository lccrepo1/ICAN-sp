ALTER PROCEDURE [dbo].[RepUnclaimedCardsXLS]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT
		a.cardno AS [CardNo],
		a.Cardname AS [CardHolder],
		b.CardTypeDesc AS [CardType],
		a.initialload AS [CreditLimit],
		a.Anniversary AS [AnniversaryDate],
		a.expirydate AS [ExpirationDate],
		c.ResidentAddress AS [Address],
		c.PhoneNo AS [ContactNumber],
		c.CompanyName AS [CompanyName],
		c.BusinessAddress AS [WorkAddress],
		c.Occupation AS [Position],
		c.SalesSpecialist AS [SalesSpecialist]
	FROM
		dbo.tblRFIDSerials a
		INNER JOIN dbo.tblCardType b ON a.Cardtype = b.CardType 
		LEFT JOIN dbo.tblCustomer c ON a.CustomerID = c.CustomerID
			AND a.AccountNumber = c.AccountNo
	WHERE
		a.IsIssued = 0
	ORDER BY
		a.Cardname
END
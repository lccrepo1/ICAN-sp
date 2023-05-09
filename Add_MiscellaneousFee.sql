ALTER PROCEDURE [dbo].[Add_MiscellaneousFee]
	@cardno varchar(50),
	@dateissued datetime,
	@typeOfFee as varchar(20),
	@amount as decimal(18,2),
	@receiptNo as char(20),
	@remarks as char(100),
	@POSCode as char(10),
	@CashierNo as char(10),
	@transtype as smallint
AS
BEGIN
	DECLARE @transtypeid int
	DECLARE @SerialNo varchar(20)
	
	-- Getting Serial Number
	SET @serialNo = (select Sno from tblRFIDSerials where cardno = @cardno)
	
	-- Getting Transtype ID
	IF TRIM(@typeOfFee) = 'Replacement Fee' BEGIN
		SET @transtypeid = 7
	END
	ELSE IF TRIM(@typeOfFee) IN ('Reactivation Fee','Renewal Fee','Annual Fee') BEGIN
		SET @transtypeid = 8
	END
	ELSE IF TRIM(@typeOfFee) = 'Filling Fee' BEGIN
		SET @transtypeid = 10
	END
	ELSE BEGIN
		SET @transtypeid = 12
	END

	-- Begin to insert
	INSERT INTO [dbo].[tblRFIDLedger]([SerialNo], [SysDate], [transactionDate], [TransTypeID], [RefNo], [ApprovalCode], [Amount], [Remarks], [POSCode], [CashierNo], [GrossAmount], [TranFee], [Begbal], [Endbal], [ReverseEntry]) VALUES (@SerialNo,@dateissued, @dateissued, @transtypeid, @receiptNo, '', (@amount * -1), @typeOfFee +' : '+ @remarks, @POSCode,@CashierNo, (@amount * -1), .00, NULL, NULL, NULL);

END
-- Created by : chan 10/19/2022
ALTER PROCEDURE [dbo].[PayFeev2]
	-- Add the parameters for the stored procedure here
	@cardno as varchar(50),
	@paydate as datetime,
	@paytype as varchar(20),
	@payamount as decimal(18,2),

	@bank as varchar(50),
	@checkno as varchar(50),
	@remarks as varchar(50),
	@receipt as varchar(15),
	@POSID char(10),
	@CashReg char(10),
	--added by chan 10/24/2022
	@TypeOfFee as varchar(20),
	@Entry as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @cnt as int

	Select @cnt = count(refno) from tblRFIDLedger where transtypeid in (2,11) and rtrim(refno) = rtrim(@receipt)

	if @cnt = 0 
		Begin
			-- Insert statements for procedure here

			Declare @refno as varchar(15)
			Declare @appcode as char(6)
			Declare @sno as varchar(20)
			
			Declare @entryno as int
			
			set @sno = (Select top 1 sno from tblRFIDSerials where cardno = @cardno)
			--set @refno =  (Select convert(varchar(6),Getdate(),12) + replace(convert(varchar(8),Getdate(),108),':',''))
			set @appcode = (SELECT SUBSTRING(CONVERT(VARCHAR(255), NEWID()),0,7))
			
			set @refno = @receipt 
			
			INSERT INTO dbo.tblRFIDLedger ([SerialNo],[SysDate],[transactionDate],[RefNo],[ApprovalCode],[Amount],[Remarks],[GrossAmount],[TransTypeID],[POSCode],[CashierNo]) 
				Values (@sno,GetDate(),@paydate,@refno,@appcode,@PayAmount,@paytype + ' : ' + @remarks,@PayAmount,11,@POSID,@CashReg)
			
			Select top 1 @entryno = entryno from tblRFIDLedger order by entryno desc
			
			--added by chan 10/24/2022
			insert into tblMiscellaneousFeeType(EntryNo,TypeOfFee)
			values(@entryno, @TypeOfFee)			
			
			--set @entryno = SCOPE_IDENTITY();
			
			--Update dbo.tblRefGen 
			--set RefGenNo = @refno 
			--where RefGenID = 2
			
			-- START : IF PAYMENT IS CHECK MODE
			if @paytype = 'Check'
				INSERT INTO dbo.tblCheckPayment([BankName],[CheckNo],[CheckAmount],[EntryNo])
					VALUES (@bank,@checkno,@payamount,@entryno)
			-- END : FOR CHECK PAYMENT MODE

			Declare @billdate as datetime
			Declare	@feetype as varchar(50)
			Declare @FeeAmount as decimal(18,2)
			Declare @refid as int

			DECLARE @PayCursor CURSOR

			SET @PayCursor = CURSOR FAST_FORWARD
			FOR  
				Select 
				convert(varchar(10),b.SysDate,101) as [Bill Date],
				c.Description as [Fee],
				abs(b.Amount) - (Select Isnull(sum(amount),0) from tblPaymentDetails where RefID = b.EntryNo and DeductionType = 'Fees') as Amount,
				b.EntryNo
				from dbo.tblRFIDSerials a inner join
				dbo.tblRFIDLedger b on a.Sno = b.SerialNo inner join
				dbo.tblTransType c on c.TransTypeID = b.TransTypeID 
				--where (b.TransTypeID in (3,7,8,10)) and a.cardno = @cardno
				-- Edited Jan 03 2023
				where (b.TransTypeID in (3,7,8,10,12)) and a.cardno = @cardno
				and b.Amount < 0 and b.EntryNo = @Entry
								
			OPEN @PayCursor
						
			FETCH NEXT FROM @PayCursor
			INTO @billdate,@feetype,@FeeAmount,@refid
			WHILE @@FETCH_STATUS = 0
				BEGIN
			
				if @payamount >= @FeeAmount
					Begin
						INSERT INTO tblPaymentDetails(transdate,sysdate,sno,RefNo,DeductionType,Amount,DueDate,RefID)
							Select @paydate,GETDATE(),@sno,@refno,'Fees',@FeeAmount,@billdate,@refid  	
					
						set @payamount = @payamount - @FeeAmount
						
						--If @feetype = 'Membership' or @feetype = 'Renewal' or @feetype = 'Replacement'
						If @feetype = 'Membership Fee' or @feetype = 'Renewal Fee' or @feetype = 'Replacement Fee'
							Begin
								Update tblInventory set status = 'Issued' where sno = @sno
								
								Update tblRFIDSerials 
									set isissued = 1,DateIssued = @paydate
								where sno = @sno
								
								
							End
					End
				else if @payamount <> 0
					Begin
						INSERT INTO tblPaymentDetails(transdate,sysdate,sno,RefNo,DeductionType,Amount,DueDate,RefID)
							Select @paydate,GETDATE(),@sno,@refno,'Fees',@payamount,@billdate,@refid
						
						set @payamount = 0
						
						--If @feetype = 'Membership' or @feetype = 'Renewal' or @feetype = 'Replacement'
						If @feetype = 'Membership Fee' or @feetype = 'RenewalFee' or @feetype = 'Replacement Fee'
							Begin
								Update tblInventory set status = 'Issued' where sno = @sno
								
								Update tblRFIDSerials 
									set isissued = 1,DateIssued = @paydate
								where sno = @sno
							
							End
					End	
			FETCH NEXT FROM @PayCursor
			INTO @billdate,@feetype,@FeeAmount,@refid
				END
			CLOSE @PayCursor
			DEALLOCATE @PayCursor
			Select 0	 
		End
	else
		Begin
			Select 1
		End
END
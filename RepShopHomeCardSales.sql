/*
* AUTHOR : CHRISTIAN CERNECHEZ
* December 07, 2022
*/
ALTER PROCEDURE [dbo].[RepShopHomeCardSales]
@fdate as varchar(100),
@tdate as varchar(100),
@sbu as varchar(8)
AS
BEGIN
	
	-- Set no count
	SET NOCOUNT ON
	
	-- Declare condition option
	DECLARE @SQLcondition nvarchar(800)
	-- Declare query
	DECLARE @SQLString nvarchar(800)
	
	DECLARE @total varchar(50)
	
	-- Declare Temporary Table
	DECLARE @tmpTbl table(
		[strnum] varchar(10),
		[strnam] varchar(50),
		[slsamnt] decimal(18,2),
		[hf] decimal(18,2),
		[total] decimal(18,2),
		[cardcnt] int,
		[trxncnt] int,
		[rate] decimal(18,2),
		[ccdsales] decimal(18,2)
	)
	
	
	
	-- Categorize first if the SBU is DS, SMR, EMR
	IF @sbu = 'SMR' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%SMR%'' or MerchantName like ''%supermarket%'''
	END
	ELSE IF @sbu = 'DS' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%DS%'' or MerchantName like ''%department store%'''
	END
	ELSE IF @sbu = 'EMR' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%EMR%'' or MerchantName like ''%express mart%'''
	END
	ELSE IF @sbu = 'MKP' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%MKP%'' or MerchantName like ''%market plus%'' or MerchantName like ''%marketplus%'''
	END
	ELSE IF @sbu = 'MSV' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%MSV%'' or MerchantName like ''%market saver%'' or MerchantName like ''%marketsaver%'''
	END
	ELSE IF @sbu = 'FC' BEGIN
		SET @SQLcondition = N' where MerchantName like ''%FC%'''
	END
	ELSE BEGIN
		SET @SQLcondition = N''
	END

	-- Set the SQLString
	SET @SQLString = N'select POSCode, MerchantName,
	ISNULL((select dbo.func_ShopHomeCardSales(''GROSSAMOUNT'',POSCode,'''+ @fdate +''','''+ @tdate +''')),0.00),
	ISNULL((select dbo.func_ShopHomeCardSales(''HANDLINGFEE'',POSCode,'''+ @fdate +''','''+ @tdate +''')),0.00),
	ISNULL((select dbo.func_ShopHomeCardSales(''TOTAL'',POSCode,'''+ @fdate +''','''+ @tdate +''')),0.00),
	CAST((select dbo.func_ShopHomeCardSales(''CARDCNT'',POSCode,'''+ @fdate +''','''+ @tdate +''')) as decimal(18,2)),
	CAST((select dbo.func_ShopHomeCardSales(''TRXNCNT'',POSCode,'''+ @fdate +''','''+ @tdate +''')) as decimal(18,2)),
	ISNULL(CAST((select dbo.func_ShopHomeCardSales(''RATE'',POSCode,'''+ @fdate +''','''+ @tdate +''')) as decimal(18,2)),0.00)
	from dbo.tblMerchants' + @SQLcondition
	
	
	
	-- Select Stores according to sbu and insert all of it to temporary table
	insert into @tmpTbl([strnum],[strnam],[slsamnt],[hf],[total],[cardcnt],[trxncnt],[rate])
	EXECUTE sp_executesql @SQLString
	
	SET @total = (SELECT SUM(slsamnt) FROM @tmpTbl)
	update @tmpTbl SET [ccdsales] = @total
	
	select * from @tmpTbl
	
	--select @SQLString
	
	
	
END
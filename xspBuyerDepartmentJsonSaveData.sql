IF  EXISTS (SELECT top 1 1 FROM sys.objects WHERE Name='xspBuyerDepartmentJsonSaveData')
	Drop PROCEDURE xspBuyerDepartmentJsonSaveData
GO
CREATE PROCEDURE xspBuyerDepartmentJsonSaveData
@guid xdtName = '',
@FromPage xdtName = NULL,
@data xdtUniCodeMaxText	= '',
@Response xdtUniCodeMaxText = '' OUTPUT
AS
BEGIN
BEGIN TRY
	DECLARE @SQLQuery xdtUnicodeMaxtext, @Buyer xdtUnicodeName, @BuyerDepartmentID xdtID, @Season xdtName, @MsgText xdtText,  @companyCode xdtCompanyCode
		, @memberCompanyCode xdtCompanyCode, @companyDivisionCode xdtCompanyCode, @userName xdtName
		, @MaxID xdtID,@errorMsg xdtUniCodeMaxText ,@ResponseID xdtID,@Status xdtName
		,@BuyerCompanyCode xdtCompanyCode ,@SortOrder xdtInt
		,@IsOrderExists int,@Sno2 bigint, @MaxSno2 bigint,@AutoCopyBuyerDepartmentInAllCompanies xdtName,@Sno1 bigint, @MaxSno1 bigint

		DECLARE @tblRetMsg TABLE (ErrorMsg xdtUniCodeLongText, ResponseID xdtID, ResponseData xdtUniCodeMaxText, [Status] xdtName)  

		SELECT @errorMsg = '', @Status = 'Success'

		EXEC xspGetSessionVariable @guid = @guid, @companyCode = @companyCode OUTPUT, @membercompanyCode = @membercompanyCode OUTPUT
		, @companyDivisionCode = @companyDivisionCode OUTPUT, @userName = @userName OUTPUT


		
		Select @AutoCopyBuyerDepartmentInAllCompanies = 0
		Select @AutoCopyBuyerDepartmentInAllCompanies = dbo.xfGetCompanySettingV1(@CompanyCode,'Misc', 'AutoCopyBuyerDepartmentInAllCompanies',@MemberCompanyCode)

		IF EXISTS(Select top 1 1 From dbo.xfGetObjectEnabled('OC') WHERE ObjectType='OC' AND IsEnabled=1)
			SET @IsOrderExists=1
		ELSE
			SET @IsOrderExists=0
		
		Create Table #BuyerDepartment (BuyerCompanyCode xdtCompanyCode,DepartmentName xdtName,SubDepartmentLevel1 xdtName,SubDepartmentLevel2 xdtName,Department xdtUniCodeLongText,Active xdtBit,TNAMandatory xdtBit)

		IF ISJSON(@data)=1
		BEGIN
			INSERT INTO #BuyerDepartment (BuyerCompanyCode,DepartmentName,SubDepartmentLevel1 ,SubDepartmentLevel2 ,Department ,Active ,TNAMandatory )
			SELECT BuyerCompanyCode,DepartmentName,SubDepartmentLevel1 ,SubDepartmentLevel2 ,Department ,Active ,TNAMandatory
			FROM OPENJSON(JSON_QUERY(@Data, '$'))
			WITH ( BuyerCompanyCode xdtCompanyCode '$.BuyerCompanyCode'
			, DepartmentName xdtName '$.DepartmentName'  
			, SubDepartmentLevel1 xdtName '$.SubDepartmentLevel1'
			, SubDepartmentLevel2 xdtName '$.SubDepartmentLevel2'
			, Department xdtUniCodeLongText '$.Department'
			, Active xdtBit '$.Active'
			, TNAMandatory xdtBit '$.TNAMandatory')	
				
			EXEC xspGetMaxID @CompanyCode=@CompanyCode,@TableName='xtBuyerDepartment',@maxID=@MaxID output  
			INSERT INTO xtBuyerDepartment(ID,BuyerCompanyCode,DepartmentName,SubDepartmentLevel1 ,SubDepartmentLevel2 ,Department ,Active ,TNAMandatory,CompanyCode,MemberCompanyCode,CreatedOn,CreatedBy,CompanyDivisionCode)
			SELECT @MaxID,BuyerCompanyCode,DepartmentName,SubDepartmentLevel1 ,SubDepartmentLevel2 ,Department ,Active ,TNAMandatory,@companyCode,@memberCompanyCode,GETDATE(),@userName,@companyDivisionCode
			FROM #BuyerDepartment 

			select @ResponseID = @MaxID
			CREATE TABLE #BuyerCompanyCodeTemp (BuyerCompanyCode xdtCode)
			INSERT #BuyerCompanyCodeTemp(BuyerCompanyCode)
			Select BuyerCompanyCode From #BuyerDepartment 
		
			Declare @CompanyList table(Sno int identity,MemberCompanyCode xdtName,CompanyDivisionCode xdtName)

			IF @IsOrderExists = 0 or @AutoCopyBuyerDepartmentInAllCompanies = '1' 
				Insert into @CompanyList(MemberCompanyCode,CompanyDivisionCode)
				Select a.CompanyCode,b.ID
				From xtCompanyGroupCompany a
				JOIN xtUserGroup b on b.MemberCompanyCode=a.CompanyCode
				join xtCompanyAddresses c on c.CompanyCode = b.CompanyCode and c.MemberCompanyCode = b.MemberCompanyCode and  c.addressCode = b.title 
			ELSE
				Insert into @CompanyList(MemberCompanyCode,CompanyDivisionCode)
				Select @MemberCompanyCode,@CompanyDivisionCode

			ALTER TABLE #BuyerCompanyCodeTemp ADD SrNo int IDENTITY(1,1)
			SELECT @Sno1 = 1, @MaxSno1 = COUNT(1) FROM #BuyerCompanyCodeTemp		

			WHILE @Sno1 <= @MaxSno1
			BEGIN
				select @BuyerCompanyCode = BuyerCompanyCode FROM #BuyerCompanyCodeTemp

				SELECT @Sno2 = 1, @MaxSno2 = COUNT(1) FROM @CompanyList
				WHILE @Sno2 <= @MaxSno2
				BEGIN
					Select @memberCompanyCode=memberCompanyCode,@CompanyDivisionCode=CompanyDivisionCode from @CompanyList where Sno=@Sno2

					Exec xspCopyBuyerDepartMent @CreatedBy =@userName,@CompanyCode =@companyCode,@MemberCompanyCode =@memberCompanyCode,@CompanyDivisionCode =@companyDivisionCode,
						@BuyerCompanyCode=@BuyerCompanyCode,@errormsg=@errormsg output

					if isnull(@errormsg,'')<>''
						Return

					SET @Sno2 = @Sno2 + 1
				END
			
				SET @Sno1 = @Sno1 + 1
			END

		END

END TRY
BEGIN CATCH
	IF ISNULL(@errorMsg,'') = '' 
			SELECT @errorMsg = ERROR_MESSAGE() 
		SELECT @errorMsg = ' Error in procedures:' + ISNULL(ERROR_PROCEDURE(), OBJECT_NAME(@@PROCID)) + ', message: ' + ISNULL(@errorMsg, '') +  ISNULL(', line: ' + CAST(ERROR_LINE() AS VARCHAR), '') 
	END CATCH

	SELECT @errorMsg = ISNULL(@errorMsg,'')

	IF @errorMsg <> '' 
		SELECT @Status = 'Fail'
	INSERT INTO @tblRetMsg(ResponseID,ErrorMsg,[Status]) SELECT 0,@errorMsg,@Status 
	SELECT @response= (SELECT @ResponseID ResponseID,ErrorMsg,[Status] FROM @tblRetMsg FOR JSON AUTO,WITHOUT_ARRAY_WRAPPER)                   
	
SET NOCOUNT OFF
END
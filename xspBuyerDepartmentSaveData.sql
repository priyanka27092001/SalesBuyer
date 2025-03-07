/*<IssueID:144306>,Date:21-Oct-2019,Done By:JatinR<1218>*/
/*<IssueID:152806>,Date:27-Jan-2020,Done By:Meghanshu<1460>*/
/*<IssueID:159711>,Date:27-Apr-2020,Done By:Anit Kumar Patel<1407>*/
/*<IssueID:170681>,Date:04-Sep-2020,Done By:Rishabh Mayur<1320>*/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[xspBuyerDepartmentSaveData]') AND TYPE in (N'P', N'PC'))
	DROP PROCEDURE xspBuyerDepartmentSaveData
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE xspBuyerDepartmentSaveData
(
	@guid			xdtName,
	@action			xdtName='',
	@fromPage		xdtLongName,
	@Headerdetails	xdtUniCodeMaxText='',
	@details		xdtUniCodeMaxText='',
	@deletedIdList	xdtUniCodeMaxText='',
	@pageParams		xdtUniCodeMaxText='',
	@errormsg		xdtUniCodeMaxText='' OUTPUT 
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @companyCode xdtCompanyCode,@memberCompanyCode xdtCompanyCode,@companyDivisionCode xdtCompanyCode,@createdBy xdtName,@colList xdtMaxText,@partyCompanyCode xdtCode,
		@Sno1 bigint, @MaxSno1 bigint,@BuyerCompanyCode xdtCode,@IsOrderExists int,@Sno2 bigint, @MaxSno2 bigint,@AutoCopyBuyerDepartmentInAllCompanies xdtName

		EXEC xspGetSessionVariable @guid = @guid, @companyCode = @companyCode OUTPUT, @membercompanyCode = @membercompanyCode OUTPUT,
			@companyDivisionCode = @companyDivisionCode OUTPUT, @userName = @createdBy OUTPUT

		Select @AutoCopyBuyerDepartmentInAllCompanies = 0
		Select @AutoCopyBuyerDepartmentInAllCompanies = dbo.xfGetCompanySettingV1(@CompanyCode,'Misc', 'AutoCopyBuyerDepartmentInAllCompanies',@MemberCompanyCode)

		IF EXISTS(Select top 1 1 From dbo.xfGetObjectEnabled('OC') WHERE ObjectType='OC' AND IsEnabled=1)
			SET @IsOrderExists=1
		ELSE
			SET @IsOrderExists=0

		IF ISNULL(@pageParams,'') <>''
		BEGIN
			CREATE TABLE #PageParam(ParamName VARCHAR(1000),ParamValue NVARCHAR(MAX))
			EXEC dbo.xspGetTableFromString @Details =@pageParams,@RowSeprator ='~',@ColumnSeperator ='|',@TableName ='#PageParam'
			Select @partyCompanyCode=ParamValue From #PageParam Where ParamName='partyCompanyCode'
		END
		
		CREATE TABLE [dbo].[#BuyerDepartment](ID xdtID,DepartmentName xdtUniCodeLongText)
		
	    ALTER TABLE #BuyerDepartment ADD BuyerCompanyCode xdtCode,Department xdtName,SubDepartmentLevel1 xdtName,SubDepartmentLevel2 xdtName,Active xdtTinyNum,TNAMandatory xdtTinyNum,[TimeStamp] bigint
			
		CREATE TABLE #DeletedBuyerDepartment([ID] DECIMAL(28,0))
		CREATE TABLE #ErrorBuyerDepartment(RowID decimal(28,0), NewRowID decimal(28,0))
		

		IF ISNULL(@details,'') <> ''
			EXEC dbo.xspGetTableFromString @Details =@details,@RowSeprator ='~',@ColumnSeperator ='|',@TableName ='#BuyerDepartment'
			
		IF ISNULL(@deletedIdList,'') <> ''
			EXEC dbo.xspGetTableFromString @Details =@deletedIdList,@RowSeprator ='~',@ColumnSeperator ='|',@TableName ='#DeletedBuyerDepartment'
	
		ALTER TABLE #BuyerDepartment ADD CompanyCode xdtCompanyCode,Createdby xdtName,Createdon xdtDate,LastChanged xdtLastChanged,
										MemberCompanyCode xdtCompanyCode,CompanyDivisionCode xdtCompanyCode

		UPDATE #BuyerDepartment SET CompanyCode=@companyCode,Createdby=@createdBy,Createdon=GETDATE(),LastChanged=GETDATE(),
		MemberCompanyCode=@memberCompanyCode,CompanyDivisionCode=@companyDivisionCode

		SET @colList = 'BuyerCompanyCode,DepartmentName,SubDepartmentLevel1,SubDepartmentLevel2,Department,Active,CompanyCode,Createdby,Createdon,'
		SET @colList = @colList + 'LastChanged,MemberCompanyCode,CompanyDivisionCode,TNAMandatory'

		if (@fromPage = 'WFXPartyDepartment')
		begin
			UPDATE #BuyerDepartment SET BuyerCompanyCode=@partyCompanyCode
		end

		Select top 1 @ErrorMsg = 'Can not delete Buyer Department ' + ISNULL(d.Department,d.DepartmentName) + ', it is selected in Business Unit ' + c.BusinessUnitName + '.'
		From #DeletedBuyerDepartment a
		JOIN xtBusinessUnitMapping b(nolock) on b.BuyerDepartmentID=a.ID
		JOIN xtBusinessUnit c(nolock) on c.BusinessUnitID=b.BusinessUnitID
		JOIN xtBuyerDepartment d(nolock) on d.ID=a.ID
		IF ISNULL(@errormsg,'') <> ''
			RETURN

		Select top 1 @ErrorMsg = 'Can not delete Buyer Department, it is selected in Production Business Mapping.'
		From #DeletedBuyerDepartment a
		JOIN xtCompanyMapping b(nolock) on b.BuyerDepartmentID=a.ID
		JOIN xtBuyerDepartment d(nolock) on d.ID=a.ID
		IF ISNULL(@errormsg,'') <> ''
			RETURN

		EXEC xspValidateNSaveData @guid =@guid,@table='BuyerDepartment',@keyColumn='ID', @uniqueColumnList='',@insertMaxID= 1,@TableType='detail', @columnlist=@colList,@errormsg =@errormsg OUTPUT 
		IF ISNULL(@errormsg,'') <> ''
			RETURN

		CREATE TABLE #BuyerCompanyCodeTemp (BuyerCompanyCode xdtCode)
		INSERT #BuyerCompanyCodeTemp(BuyerCompanyCode)
		Select BuyerCompanyCode From #BuyerDepartment group by BuyerCompanyCode
		
		Declare @CompanyList table(Sno int identity,MemberCompanyCode xdtName,CompanyDivisionCode xdtName)

		IF @IsOrderExists = 0 or @AutoCopyBuyerDepartmentInAllCompanies = '1' 
			Insert into @CompanyList(MemberCompanyCode,CompanyDivisionCode)
			Select a.CompanyCode,b.ID
			From xtCompanyGroupCompany a
			JOIN xtUserGroup b on b.MemberCompanyCode=a.CompanyCode
			join xtCompanyAddresses c (NOLOCK) on c.CompanyCode = b.CompanyCode and c.MemberCompanyCode = b.MemberCompanyCode and  c.addressCode = b.title 
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

				Exec xspCopyBuyerDepartMent @CreatedBy =@createdBy,@CompanyCode =@companyCode,@MemberCompanyCode =@memberCompanyCode,@CompanyDivisionCode =@companyDivisionCode,
					@BuyerCompanyCode=@BuyerCompanyCode,@errormsg=@errormsg output

				if isnull(@errormsg,'')<>''
					Return

				SET @Sno2 = @Sno2 + 1
			END
			
			SET @Sno1 = @Sno1 + 1
		END

		IF ISNULL(@errormsg,'') <> ''
			RETURN
		Select *,'' [Error],0 [TimeStamp] from #ErrorBuyerDepartment

	END TRY
	BEGIN CATCH
		SET @errorMsg = 'Error in xspBuyerDepartmentSaveData: ' + ERROR_MESSAGE()
	END CATCH
END
/*<IssueID:152806>,Date:27-Jan-2020,Done By:Meghanshu<1460>*/
/*<IssueID:170681>,Date:04-Sep-2020,Done By:Rishabh Mayur<1320>*/

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[xspBuyerDepartmentGetList]') AND TYPE in (N'P', N'PC'))
DROP PROCEDURE xspBuyerDepartmentGetList
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE xspBuyerDepartmentGetList
(
	@guid xdtName,
	@fromPage xdtLongName, 
	@pageParams xdtUniCodeMaxText='',
	@searchParams xdtUniCodeMaxText='',
	@sortParams xdtUniCodeLongText='',
	@pageIndex xdtSmallNum=1,
	@pageSize xdtSmallNum=20,
	@errorMsg xdtUniCodeMaxText='' OUTPUT,
	@response xdtUniCodeMaxText='' OUTPUT
)
AS
SET NOCOUNT ON;
BEGIN
	DECLARE @companyCode xdtCompanyCode,@memberCompanyCode xdtCompanyCode,@companyDivisionCode xdtCompanyCode,@userName xdtName,@RecordCount bigint,
			@Buyer xdtUnicodeLongName,@DepartmentName xdtName,@SubDepartmentLevel1 xdtName,@SubDepartmentLevel2 xdtName,@ID xdtID,@partyCompanyCode xdtCode,
			@GetJSONData xdtTinyNum,@ResponseData xdtUniCodeMaxText,@SearchDepartmentName xdtName

	EXEC xspGetSessionVariable @guid=@guid ,@companyCode =@companyCode  OUTPUT,@membercompanyCode =@membercompanyCode  OUTPUT,
								@companyDivisionCode =@companyDivisionCode  OUTPUT,@userName =@userName OUTPUT

	IF (ISNULL(@searchParams,'') <>'')
	BEGIN
		CREATE TABLE #SearchParam(ParamName NVARCHAR(1000),ParamValue NVARCHAR(MAX))
		EXEC dbo.xspGetTableFromString @details =@searchParams,@rowSeprator ='~',@columnSeperator ='|',@tableName ='#SearchParam'
		 SELECT @Buyer = ParamValue From #SearchParam WHERE ParamName='colBuyer'
		 SELECT @DepartmentName = ParamValue From #SearchParam WHERE ParamName='colDepartmentName'
		 SELECT @SubDepartmentLevel1 = ParamValue From #SearchParam WHERE ParamName='colSubDepartmentLevel1'
		 SELECT @SubDepartmentLevel2 = ParamValue From #SearchParam WHERE ParamName='colSubDepartmentLevel2'
	END

	IF ISNULL(@pageParams,'') <>''
	BEGIN
		CREATE TABLE #PageParam(ParamName VARCHAR(1000),ParamValue NVARCHAR(MAX))
		EXEC dbo.xspGetTableFromString @Details =@pageParams,@RowSeprator ='~',@ColumnSeperator ='|',@TableName ='#PageParam'
		Select @ID=ParamValue From #PageParam Where ParamName='ID'
		Select @partyCompanyCode=ParamValue From #PageParam Where ParamName='partyCompanyCode'
		Select @GetJSONData=ParamValue From #PageParam Where ParamName='GetJSONData'
		Select @Buyer=ParamValue From #PageParam where ParamName = 'BuyerCompanyName'
		Select @MemberCompanyCode=ParamValue From #PageParam where ParamName = 'MemberCompanyCode'
		Select @CompanyDivisionCode=ParamValue From #PageParam where ParamName = 'CompanyDivisionCode'
		Select @SearchDepartmentName=ParamValue From #PageParam where ParamName = 'DepartmentName'
	END
	
	IF @fromPage = 'CtrlWFXAPIDepartmentController' AND @guid = '' AND @GetJSONData=1
	BEGIN
		SELECT @companyCode = CompanyCode FROM xtCompanyGroupCompany WHERE CompanyCode = GroupCompanyCode
		
		IF ISNULL(@MemberCompanyCode,'0') ='0' OR ISNULL(@MemberCompanyCode,'') = ''
		BEGIN
			Select @errorMsg='Please Enter MemberCompanyCode.' 
			RETURN
		END
	END

	

	CREATE TABLE #BuyerDepartment(BuyerCompanyCode xdtCode,Buyer xdtText,ID xdtID,DepartmentName xdtUnicodelongtext,SubDepartmentLevel1 xdtName,SubDepartmentLevel2 xdtName,
				Department xdtUnicodelongtext,Active xdtTinyNum,IsDeletable int,TNAMandatory xdtTinyNum,CompanyCode xdtCompanyCode,MemberCompanyCode xdtCompanyCode,
				MemberCompanyName xdtunicodeName,CompanyDivisionCode xdtCompanyCode,CompanyDivisionName xdtunicodeName)

	INSERT INTO #BuyerDepartment(BuyerCompanyCode,Buyer,ID,DepartmentName,SubDepartmentLevel1,SubDepartmentLevel2,Department,Active,IsDeletable,TNAMandatory,
			CompanyCode,MemberCompanyCode,CompanyDivisionCode)
	SELECT b.BuyerCompanyCode [BuyerCode],c.CompanyName [Buyer], b.ID [ID],b.Department [DepartmentName], b.SubDepartmentLevel1,b.SubDepartmentLevel2,
	b.DepartmentName [Department],ISNULL(b.Active, 1) [Active], 1 [IsDeletable],ISNULL(b.TNAMandatory,0),b.CompanyCode,b.MemberCompanyCode,b.CompanyDivisionCode
	FROM xtBuyerDepartment b (NOLOCK)
	JOIN xtCompany c (NOLOCK) ON c.MemberCompanyCode = b.BuyerCompanyCode
	JOIN xtPartyGroupDetail p (NOLOCK) ON p.PartyCompanyCode=c.MemberCompanyCode and p.MemberCompanyCode=@memberCompanyCode and p.BuyerSeller='1' and p.Inactive='0' and p.partygroupid <> 0 
	WHERE (ISNULL(@partyCompanyCode,0) = 0 OR b.BuyerCompanyCode =@partyCompanyCode)
	AND (ISNULL(@ID,0) = 0 OR b.ID =@ID)
	AND (ISNULL(@Buyer,'') = '' OR c.CompanyName LIKE '%' + @Buyer + '%')
	AND (ISNULL(@DepartmentName,'') = '' OR b.DepartmentName LIKE '%' + @DepartmentName + '%')
	AND (ISNULL(@SearchDepartmentName,'') = '' OR b.DepartmentName =@SearchDepartmentName)
	AND (ISNULL(@SubDepartmentLevel1,'') = '' OR b.SubDepartmentLevel1 LIKE '%' + @SubDepartmentLevel1 + '%')
	AND (ISNULL(@SubDepartmentLevel2,'') = '' OR b.SubDepartmentLevel2 LIKE '%' + @SubDepartmentLevel2 + '%')
	AND (@fromPage <> 'CtrlWFXAPIDepartmentController' OR ISNULL(@CompanyDivisionCode,'') = '' OR b.CompanyDivisionCode LIKE '%' + @CompanyDivisionCode + '%')
	AND (@fromPage <> 'CtrlWFXAPIDepartmentController' OR b.MemberCompanyCode = @memberCompanyCode)
	Group by b.BuyerCompanyCode ,c.CompanyName, b.ID,b.DepartmentName, b.SubDepartmentLevel1,b.SubDepartmentLevel2,b.Department,ISNULL(b.Active, 1),
		ISNULL(b.TNAMandatory,0),b.CompanyCode,b.MemberCompanyCode,b.CompanyDivisionCode

	UPDATE #BuyerDepartment SET Department = DepartmentName WHERE ISNULL(Department,'') = ''
	
	IF @GetJSONData =1 
	BEGIN
		UPDATE c  SET MemberCompanyName = a.companyname
		from #BuyerDepartment c
		JOIN  xtCompany a on a.CompanyCode = c.CompanyCode and  c.MemberCompanyCode = a.MemberCompanyCode
		WHERE a.Companycode = @companyCode 
		
		UPDATE a  set CompanyDivisionName = b.DivisionName 
		from #BuyerDepartment a
		JOIN vwUserGroupDivisionPermissions b on b.FolderID = a.CompanyDivisionCode

		SELECT @ResponseData = (SELECT BuyerCompanyCode,buyer [BuyerCompanyName],DepartmentName,ID [DepartmentID],CompanyCode,MemberCompanyCode,MemberCompanyName
								,CompanyDivisionCode,CompanyDivisionName FROM #BuyerDepartment for json path)
			
		SELECT @response=@ResponseData
	END
	ELSE
	BEGIN
		IF(ISNULL(@sortParams,'')='')SELECT @sortParams= 'colBuyer|ASC'

		SELECT * INTO #BuyerDepartmentFinal FROM #BuyerDepartment WHERE 1=2

		SELECT @RecordCount = COUNT(1) FROM #BuyerDepartment
		
		EXEC xspGetPageData @sourceTable ='#BuyerDepartment',@sortParams = @sortParams,@pageIndex=@pageIndex,@pageSize=@pageSize,
		@numericColList = '', @dateColList='',@errorMsg=@errorMsg OUT

		Update a set IsDeletable=0
		From #BuyerDepartmentFinal a
		JOIN xtBusinessUnitMapping b(nolock) on ISNULL(b.BuyerDepartmentID,0)=a.ID

		Update a set IsDeletable=0
		From #BuyerDepartmentFinal a
		JOIN xtCompanyMapping b(nolock) on ISNULL(b.BuyerDepartmentID,0)=a.ID

		Update a set IsDeletable=0
		From #BuyerDepartmentFinal a
		JOIN xtPartyProductSubCategory b(nolock) on ISNULL(b.BuyerDepartmentID,0)=a.ID AND b.PartyCompanyCode=a.BuyerCompanyCode

		Update a set IsDeletable=0
		From #BuyerDepartmentFinal a
		JOIN xtPartySampleType b on b.BuyerDepartmentID=a.ID AND b.PartyCompanyCode=a.BuyerCompanyCode

		Update a set IsDeletable=0
		From #BuyerDepartmentFinal a
		JOIN xtPartyContactBuyerDepartment b on b.BuyerDepartmentID=a.ID
		JOIN xtPartyContact c on  c.PartyContactID=b.PartyContactID AND c.PartyCompanyCode=a.BuyerCompanyCode

	
		SELECT * FROM #BuyerDepartmentFinal ORDER BY RowNo ASC

		SELECT COUNT(1) [RecordCount] FROM #BuyerDepartment
		select -1 [BuyerCompanyCode],'' [Buyer],0 [ID],'' [DepartmentName],'' [SubDepartmentLevel1],'' [SubDepartmentLevel2],'' [Department],1 [Active],0 [TNAMandatory]

	END		
END	
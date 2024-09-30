--Link to Article:
--https://www.mssqltips.com/sqlservertip/3479/how-to-use-a-multi-valued-comma-delimited-input-parameter-for-an-ssrs-report/

--CREATE TABLE #ProductNumberBlank ([Product #] VARCHAR(MAX))




declare @ProductNumberPar as varchar (max)

set @ProductNumberPar = 'BA%,BB%,BE%,BK-R93R-62,FR-____-60,%-1000,%-[4-5][0-2]'
--set @ProductNumberPar = ''
--set @ProductNumberPar = '%'

select @ProductNumberPar as [Parameter String]

CREATE TABLE #ProductNumber ([Product #] VARCHAR(MAX))




 /*INSERTING EACH COMMA SEPERATED VALUE INTO TEMP TABLE except the last Product in the CSV*/

  WHILE CHARINDEX(',',@ProductNumberPar) <> 0 
  BEGIN
		select CHARINDEX(',',@ProductNumberPar) as [While Loop Condition]
		/*Takes the Parameter String of CSV(s) & inserts the left most Product during each iteration*/
		(SELECT LEFT(@ProductNumberPar, CHARINDEX(',',@ProductNumberPar)-1)as [Left Most Product])
    INSERT INTO #ProductNumber VALUES((SELECT LEFT(@ProductNumberPar, CHARINDEX(',',@ProductNumberPar)-1)))
		/*Takes the Parameter String of CSV(s) & eliminated the left most Product during each iteration*/
		(SELECT RIGHT(@ProductNumberPar,LEN(@ProductNumberPar)-CHARINDEX(',',@ProductNumberPar))as [New Parameter String Iteration]) 
    SET @ProductNumberPar = (SELECT RIGHT(@ProductNumberPar,LEN(@ProductNumberPar)-CHARINDEX(',',@ProductNumberPar)))
  END

 select CHARINDEX(',',@ProductNumberPar) as [Last While Loop Condition]
 select @ProductNumberPar as [Last Product Yet to be Inserted]
 select [Product #] as [Product Table List Before Last Product is Inserted] from #ProductNumber

 /*Inserts the last CSV value into the Temp Table*/
 insert into #ProductNumber values ((select @ProductNumberPar))
--select @ProductNumberPar into #ProductNumber

select [Product #] as [Final Product Table List] from #ProductNumber

--drop table #ProductNumber



-----Wildcard Searches of All Products Inputed into #ProductNumber--------------------------------------------------------------------------------------------------------------------- 


/* 
Assigns an index number to each partial Product number so that each wildcard Product index will
correspond to a counter value for the loop below.
*/
select 
ROW_NUMBER() over(order by #ProductNumber.[Product #]) as [Primary Key]
,#ProductNumber.[Product #] as [ProductNumber]
into #ProductNumberWithPK
from #ProductNumber

select [Primary Key] ,[ProductNumber] as [Final Product Table List with Index] from #ProductNumberWithPK



create table #ProductNumberWildcardLoop (ProductNumber varchar (max) )


--select * from #ProductNumberWithPK
--drop table #ProductNumberWithPK


declare @Counter int
declare @NumOfProducts int
declare @SelectedProduct varchar(20)

set @Counter = 1
set @NumOfProducts = (select COUNT(*) from #ProductNumberWithPK)
--print cast(@NumOfProducts as varchar(10) ) + ' Products'

/*
For each indexed partial Product string in #ProductNumberWithPK,
insert into #ProductNumberWildcardLoop all Products that contain each partial Product.
*/

while @Counter <= @NumOfProducts
	begin
		set @SelectedProduct = (select #ProductNumberWithPK.ProductNumber from #ProductNumberWithPK where [Primary Key] = @Counter)
		--print cast(@Counter as varchar(20) ) + ' - ' + @SelectedProduct
		--select @SelectedProduct as [Nth Product]
		insert into #ProductNumberWildcardLoop
		/*
		select distinct Product numbers from transaction table
		
		where [Product #] like '%' + @SelectedProduct + '%' 
		*/
		select distinct [ProductNumber] --,[ProductID]
		FROM [AdventureWorks2019].[Production].[Product] 
		where [ProductNumber] like  @SelectedProduct 
		--where [ProductNumber] like '%' + @SelectedProduct + '%' --Old Method

		set @Counter = @Counter + 1
	end

select #ProductNumberWildcardLoop.ProductNumber as [Final Product List After Wildcard Search] from #ProductNumberWildcardLoop
--drop table #ProductNumberWildcardLoop

--drop table #ProductNumber
--drop table #ProductNumberWithPK
--drop table #ProductNumberBlank
-----------------------------------------------------------------------------------------------------------------------------------------------------------------




select 
	SH.[SalesOrderID]
    ,SH.[RevisionNumber]
    ,SH.[OrderDate]
    ,SH.[DueDate]
    ,SH.[ShipDate]
    ,SH.[Status]
    ,SH.[OnlineOrderFlag]
    ,SH.[SalesOrderNumber]
    ,SH.[PurchaseOrderNumber]
    ,SH.[AccountNumber]
    ,SH.[CustomerID]
    ,SH.[SalesPersonID]
    ,SH.[BillToAddressID]
    ,SH.[ShipToAddressID]
    ,SH.[ShipMethodID]
    ,SH.[CreditCardID]
    ,SH.[CreditCardApprovalCode]
    ,SH.[CurrencyRateID]
    ,SH.[SubTotal]
    ,SH.[TaxAmt]
    ,SH.[Freight]
    ,SH.[TotalDue]
    ,SH.[Comment]
    --,SH.[rowguid]
    --,SH.[ModifiedDate]

	--,SD.[SalesOrderID]
	,SD.[SalesOrderDetailID]
	,SD.[CarrierTrackingNumber]
	,SD.[OrderQty]
	,SD.[ProductID]
	,SD.[SpecialOfferID]
	,SD.[UnitPrice]
	,SD.[UnitPriceDiscount]
	,SD.[LineTotal]
	,SD.[rowguid]
	,SD.[ModifiedDate]

	,Terr.TerritoryID
	,Terr.[Name] as [Territory Name]
	,Terr.[Group] as [Territory Group]

into
	#SalesOrderTable
from 
	[AdventureWorks2019].[Sales].[SalesOrderHeader] as SH
inner join
	[AdventureWorks2019].[Sales].[SalesOrderDetail] as SD
on
	SH.SalesOrderID = SD.SalesOrderID
inner join
	[AdventureWorks2019].[Sales].[SalesTerritory] as [Terr]
on
	SH.TerritoryID = Terr.TerritoryID
order by
	SH.SalesOrderID
	,SD.ProductID



--Customer & Location Info
select 
	BE.[BusinessEntityID]
	,BE.[rowguid]
	,BE.[ModifiedDate]

	--,BEA.[BusinessEntityID]
	--,BEA.[AddressID]
	--,BEA.[AddressTypeID]

	,[AT].[AddressTypeID]
	,[AT].[Name]

	,AD.[AddressID]
	,AD.[AddressLine1]
	,AD.[AddressLine2]
	,AD.[City]
	,AD.[PostalCode]
	,AD.[SpatialLocation]

	,S.[Name] as [Store Name]

	,SP.StateProvinceID
	,SP.StateProvinceCode

	,CR.CountryRegionCode
	,CR.[Name] as [Country Region Name]

into
	#CustomersTable
from 
	[AdventureWorks2019].[Person].[BusinessEntity] as BE
inner join 
	[AdventureWorks2019].[Person].[BusinessEntityAddress] as BEA
on 
	BE.BusinessEntityID = BEA.BusinessEntityID
inner join 
	[AdventureWorks2019].[Person].[AddressType] as [AT]
on 
	BEA.AddressTypeID = [AT].AddressTypeID
inner join 
	[AdventureWorks2019].[Person].[Address] as [AD]
on 
	BEA.AddressID = AD.AddressID
inner join
	[AdventureWorks2019].[Person].[StateProvince] as [SP]
on
	AD.StateProvinceID = SP.StateProvinceID
inner join
	[AdventureWorks2019].[Person].[CountryRegion] as [CR]
on
	SP.CountryRegionCode = CR.CountryRegionCode
left join
	[AdventureWorks2019].[Sales].[Store] as [S]
on
	BE.BusinessEntityID = S.BusinessEntityID
--where 
--	[AT].AddressTypeID = 5
order by 
	BEA.AddressID --BE.BusinessEntityID 




select 
	ProductID
	,P.ProductNumber
	,P.Name as [Product Name]
	,P.Color
	,P.ListPrice
	,P.StandardCost
	,P.SellStartDate
	,P.SellEndDate
	,Sub.ProductSubcategoryID
	,Sub.Name as [Subcategory Name]
	,Cat.ProductCategoryID
	,Cat.Name as [Category Name]

into
	#ProductsTable
from
	[AdventureWorks2019].[Production].Product as [P]
left join
	[AdventureWorks2019].[Production].ProductSubcategory as [Sub]
on
	P.ProductSubcategoryID = Sub.ProductSubcategoryID
left join
	[AdventureWorks2019].[Production].ProductCategory as [Cat]
on 
	Sub.ProductCategoryID = Cat.ProductCategoryID





--Must be exact and can't be empty.
declare @StartDate as datetime
declare @EndDate as datetime

set @StartDate = '2011-05-31'
set @EndDate = '2016-06-30'


--Exact & can be empty
declare @ProductSubcategory as varchar(30)
declare @ProductCategory as varchar(30)
declare @CustomerID as varchar(30)

set @ProductSubcategory = ''
set @ProductCategory = ''
set @CustomerID = ''


--Searchable (% wildcard) and can be empty. 
declare @ShipToAddress as varchar(30)
declare @ShipToPostalCode as varchar(30)
declare @ShipToLocationType as varchar(30)
declare @BillToAddress as varchar(30)
declare @BillToPostalCode as varchar(30)
declare @BillToLocationType as varchar(30)


set @ShipToAddress = '%'
set @ShipToPostalCode = '%'
set @ShipToLocationType = '%'
set @BillToAddress = '%'
set @BillToPostalCode = '%'
set @BillToLocationType = '%'
--Make these parameters have default value of '%'




select 
	SOT.[SalesOrderID]
	,SOT.[RevisionNumber]
    ,SOT.[OrderDate]
    ,SOT.[DueDate]
    ,SOT.[ShipDate]
    ,SOT.[Status]
    ,SOT.[OnlineOrderFlag]
    ,SOT.[SalesOrderNumber]
    ,SOT.[PurchaseOrderNumber]
    ,SOT.[AccountNumber]
    ,SOT.[CustomerID]
	,SOT.[SalesPersonID]

    ,SOT.[SubTotal]
    ,SOT.[TaxAmt]
    ,SOT.[Freight]
    ,SOT.[TotalDue]
    ,SOT.[Comment]

	,SOT.[SalesOrderDetailID]
	,SOT.[CarrierTrackingNumber]
	,SOT.[OrderQty]
	,SOT.[SpecialOfferID]
	,SOT.[UnitPrice]
	,SOT.[UnitPriceDiscount]
	,SOT.[LineTotal]
	,SOT.[rowguid]
	,SOT.[ModifiedDate]

	,SOT.TerritoryID
	,SOT.[Territory Name]
	,SOT.[Territory Group]

	,P.[ProductID]
	,P.ProductNumber
	,P.[Product Name]
	,P.Color
	,P.ListPrice
	,P.StandardCost
	,P.SellStartDate
	,P.SellEndDate
	,P.ProductSubcategoryID
	,P.[Subcategory Name]
	,P.ProductCategoryID
	,P.[Category Name]

	,ShipTo.[Store Name] as [ShipTo Location Name]
	,ShipTo.[Name] as [ShipTo Location Type]
	,ShipTo.[AddressID] as [ShipTo AddressID]
	,ShipTo.[AddressLine1] as [ShipTo AddressLine1]
	,ShipTo.[AddressLine2] as [ShipTo AddressLine2]
	,ShipTo.[City] as [ShipTo City]
	,ShipTo.[PostalCode] as [ShipTo PostalCode]
	,ShipTo.[SpatialLocation] as [ShipTo SpatialLocation]
	,ShipTo.StateProvinceID as [ShipTo StateProvinceID]
	,ShipTo.StateProvinceCode as [ShipTo State Province Code]
	,ShipTo.CountryRegionCode as [ShipTo Country Region Code]
	,ShipTo.[Country Region Name] as [ShipTo Country Region Name]


	,BillTo.[Store Name] as [BillTo Location Name]
	,BillTo.[Name] as [BillTo Location Type]
	,BillTo.[AddressID] as [BillTo AddressID]
	,BillTo.[AddressLine1] as [BillTo AddressLine1]
	,BillTo.[AddressLine2] as [BillTo AddressLine2]
	,BillTo.[City] as [BillTo City]
	,BillTo.[PostalCode] as [BillTo PostalCode]
	,BillTo.[SpatialLocation] as [BillTo SpatialLocation]
	,BillTo.StateProvinceID as [BillTo StateProvinceID]
	,BillTo.StateProvinceCode as [BillTo State Province Code]
	,BillTo.CountryRegionCode as [BillTo Country Region Code]
	,BillTo.[Country Region Name] as [BillTo Country Region Name]
	

from
	#ProductsTable as P	
left join
	#SalesOrderTable as SOT
on
	P.ProductID = SOT.ProductID
left join 
	#CustomersTable as ShipTo
on
	SOT.ShipToAddressID = ShipTo.AddressID
left join 
	#CustomersTable as BillTo
on
	SOT.BillToAddressID = BillTo.AddressID
where
		((SOT.OrderDate between @StartDate and @EndDate) or (SOT.OrderDate is null)) --Captures Products in date range and Products with no sales

--AND Conditions to handle multiple Products or ALL Products in the WHERE clause
	and
		(isnull(P.[ProductNumber],'') in(select ProductNumber from #ProductNumberWildcardLoop) or '' in(select ProductNumber from #ProductNumberWildcardLoop) )
	and
		(isnull(P.[Subcategory Name],'') = @ProductSubcategory or '' = @ProductSubcategory )
	and
		(isnull(P.[Category Name],'') = @ProductCategory or '' = @ProductCategory )
	and
		(isnull(SOT.[CustomerID],'') = @CustomerID or '' = @CustomerID  )


--Wildcard searches that return all values when '%' is passed to a variable.
	and
		(isnull(ShipTo.[AddressLine1],'') like @ShipToAddress )
	and
		(isnull(ShipTo.[PostalCode],'') like @ShipToPostalCode )
	and
		(isnull(ShipTo.[Name],'') like @ShipToLocationType )
	and
		(isnull(BillTo.[AddressLine1],'') like @BillToAddress )
	and
		(isnull(BillTo.[PostalCode],'') like @BillToPostalCode )
	and
		(isnull(BillTo.[Name],'') like @BillToLocationType )

	--and
	--	ShipToAddressID <> BillToAddressID
order by
	SOT.SalesOrderID
	,P.ProductNumber




drop table #ProductNumberWildcardLoop
drop table #ProductNumber
drop table #ProductNumberWithPK
drop table #SalesOrderTable
drop table #CustomersTable
drop table #ProductsTable
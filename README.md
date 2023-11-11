

# 1. SSRS Sales Report Project
> ## a. Table of Contents

# 2. Business Case
> ## a. Business Overview
> AdventureWorks is medium sized business that sells bikes, bike parts, and bike accessories across the United States. They sell directly to customers and to bike retailers.
> ## b. Scenario Overview
>  I have been hired as a data analyst at AdventureWorks to improve the reporting processes for more junior level business analysts, data analysts, executives, and other stakeholders across the business. AdventureWorks is growing fast and needs help improving the reporting processes across the company.
> ## c. Project Objective
> The objective of this report is to allow for analysts, sales managers, and salespeople to be able to pull Sales Order, Product, ShipTo Location, and BillTo Location information from the AdventureWorks2019 database into 1 table without having to know how to use SQL. That way the end user of the report can use pivot tables to quickly analyze 
> ## d. Project Requirements
> 1. Use SSRS as the primary reporting tool so that the end users can export the data that they need.
> 2. Include the following parameters in the report so that the end users can filter the data:
>> * This grouping of parameter(s) will allow the end user to do 3 things. If you leave the parameter blank, all possible values will return. You can also select multiple valid values. Lastly, it will allow the end user to use wildcard characters(%) to select partial results. For example, if the user enters (BA%,BB%,BE%,BK-R93R-62), the first 3 values have the wildcard symbol so all possible items starting with BA, BB, and BE would be returned. The last value in the selection (BK-R93R-62) is just an item number so only that item will be returned.
>>> 1. Item Number
>> * This grouping of parameter(s) require the user to input date values and cannot be blank. They should have default values of 1/1/2011 for the Start Date and 12/31/2016 for the end date becuase there is no data outside of that date range. 
>>> 1. Start Date
>>> 1. End Date
>> * This grouping of parameter(s) will allow the end user to do 2 things.  If you leave the parameter blank, all possible values will return. You can also select a single valid value for each of these parameters to filter down the results further. Wildcard searches will not work.
>>> 1. Product Subcategory
>>> 1. Product Category
>>> 1. Customer Account Number
>> * This grouping of parameter(s) will have the wildcard symbol(%) as the default value. This will allow the end user to do 3 things. If you leave the parameter with the default value (%), all possible values will return. You can only entera single valid value for each of these parameters to filter down the results further but you can use wildcard characters(%) to select partial results if you chose to. Note: If you delete the default value(%) and fail to replace it with a valud value, the report will return a no results becuse toy would be filtering for an invalid condition.
>>> 1. Ship To Address
>>> 1. Ship To Postal Code
>>> 1. Ship To Location Type
>>> 1. Bill To Address
>>> 1. Bill To Postal Code
>>> 1. Bill To Location Type
> 3. Use an embedded data source connection to connect the AdventureWorks2019 database.
> 4. Use a stored procedure that also can be executed using Sql Server Management Studio as the SSRS Report Dataset. This will ensure that the SQL logic isn't stored in the .rdl file and allow for future reports to be able to use that same SQL logic.
> 5. Create a SQL query with variables that mimics the stored procedure so that analysts with read only SQL access to the AdventureWorks2019 database can 
# 3. Project Steps
## a. Dig through the AdventureWorks2019 database and learn how the data is structured and organized.
Dataset schema overview.

![This is a picture of the Sales Schema from the AdventureWorks2019 database](images/AdventureWorks2019SalesSchema.jpg)

## b. Create the Stored Procedure and it's parameters.
<details>
<summary>Code Snippet</summary>

```sql
/*
Create Stored Procedure and it's parameters
*/

Create or Alter Proc dbo.[Multi Item Partial Item Search Order Data SP]
	/*
	Can contain a multiple vales seperated by a comma within the same string
	Those values can be exact values or partial values with wildcard characters to allow for exact and partial matches
	If the string is blank, it will return all possible values
	*/
	@ItemNumberPar as varchar (max)

	--Must be exact and can't be empty.
	,@StartDate as datetime
	,@EndDate as datetime

	--Exact search or can be empty
	,@ProductSubcategory as varchar(30)
	,@ProductCategory as varchar(30)
	,@CustAccountNumber as varchar(30)

	/*
	Searchable (% wildcard) and can either contain only a (%), a (%) with a partial string, or an exact search.
	Must not be blank
	*/
	,@ShipToAddress as varchar(30)
	,@ShipToPostalCode as varchar(30)
	,@ShipToLocationType as varchar(30)
	,@BillToAddress as varchar(30)
	,@BillToPostalCode as varchar(30)
	,@BillToLocationType as varchar(30)

as

```

</details>

## c. Create script that allows user to input any combination of item numbers with and without wildcard characters and returns all matching items from the database.
Script Overview


<details>
<summary>Code Snippet</summary>

```sql


--select @ItemNumberPar as [Parameter String]

CREATE TABLE #ItemNumber ([Item #] VARCHAR(MAX))


 /*
 Inserting each comma seperated value into a temp table except for the last Item in the CSV
 */

  WHILE CHARINDEX(',',@ItemNumberPar) <> 0 
  BEGIN
		--select CHARINDEX(',',@ItemNumberPar) as [While Loop Condition]
		/*Takes the Parameter String of CSV(s) & inserts the left most item during each iteration*/
		--(SELECT LEFT(@ItemNumberPar, CHARINDEX(',',@ItemNumberPar)-1)as [Left Most Item])
    INSERT INTO #ItemNumber VALUES((SELECT LEFT(@ItemNumberPar, CHARINDEX(',',@ItemNumberPar)-1)))
		/*Takes the Parameter String of CSV(s) & eliminated the left most item during each iteration*/
		--(SELECT RIGHT(@ItemNumberPar,LEN(@ItemNumberPar)-CHARINDEX(',',@ItemNumberPar))as [New Parameter String Iteration]) 
    SET @ItemNumberPar = (SELECT RIGHT(@ItemNumberPar,LEN(@ItemNumberPar)-CHARINDEX(',',@ItemNumberPar)))
  END

 --select CHARINDEX(',',@ItemNumberPar) as [Last While Loop Condition]
 --select @ItemNumberPar as [Last Item Yet to be Inserted]
 --select [Item #] as [Item Table List Before Last Item is Inserted] from #ItemNumber

 /*Inserts the last CSV value into the Temp Table*/
 insert into #ItemNumber values ((select @ItemNumberPar))
--select @ItemNumberPar into #ItemNumber

--select [Item #] as [Final Item Table List] from #ItemNumber
--drop table #ItemNumber



-------------------------------------------------------------------------------------------------------------------------- 


/* 
Assigns an index number to each partial item number so that each wildcard item index will
correspond to a counter value for the loop below.
*/
select 
ROW_NUMBER() over(order by #ItemNumber.[Item #]) as [Primary Key]
,#ItemNumber.[Item #] as [ItemNumber]
into #ItemNumberWithPK
from #ItemNumber

--select [Primary Key] ,[ItemNumber] as [Final Item Table List with Index] from #ItemNumberWithPK

--drop table #ItemNumber
--drop table #ItemNumberWithPK


-------------------------------------------------------------------------------------------------------------------------------------------------------


create table #ItemNumberWildcardLoop (ItemNumber varchar (max) )


--select * from #ItemNumberWithPK
--drop table #ItemNumberWithPK


declare @Counter int
declare @NumOfItems int
declare @SelectedItem varchar(20)

set @Counter = 1
set @NumOfItems = (select COUNT(*) from #ItemNumberWithPK)
--print cast(@NumOfItems as varchar(10) ) + ' Items'

/*
For each indexed partial item string in #ItemNumberWithPK,
insert into #ItemNumberWildcardLoop all items that contain each partial item.
*/

while @Counter <= @NumOfItems
	begin
		set @SelectedItem = (select #ItemNumberWithPK.ItemNumber from #ItemNumberWithPK where [Primary Key] = @Counter)
		--print cast(@Counter as varchar(20) ) + ' - ' + @SelectedItem
		--select @SelectedItem as [Nth Item]
		insert into #ItemNumberWildcardLoop
		/*
		select distinct item numbers from transaction table
		
		where [Item #] like '%' + @SelectedItem + '%' 
		*/
		select distinct [ProductNumber] --,[ProductID]
		FROM [AdventureWorks2019].[Production].[Product] 
		
		where [ProductNumber] like @SelectedItem
		--where [ProductNumber] like '%' + @SelectedItem + '%' 

		set @Counter = @Counter + 1
	end

--select #ItemNumberWildcardLoop.ItemNumber as [Final Item List After Wildcard Search] from #ItemNumberWildcardLoop

--drop table #ItemNumber
--drop table #ItemNumberWithPK
--drop table #ItemNumberWildcardLoop





```
</details>

## d. Clean the data an put the data into temp tables within the stored procedure
SQL Temp Tables

<details>
<summary>Code Snippet</summary>

```sql

---------------------------------------------------------------------------------------
/*
Sales Order Temp Table
*/


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

    ,SH.[SubTotal]
    ,SH.[TaxAmt]
    ,SH.[Freight]
    ,SH.[TotalDue]
    ,SH.[Comment]

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


-----------------------------------------------------------------------------------------------------
/*
Ship To & Bill To Temp Table
*/
select 
	BE.[BusinessEntityID]
	,BE.[rowguid]
	,BE.[ModifiedDate]

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
	BEA.AddressID 



-----------------------------------------------------------------------------------------------------

/*
Products Temp Table
*/

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







-----------------------------------------------------------------------------------------------------




```
</details>


## e. Join the temp tables and return the required fields for the report while filtering for the conditions passed into the stored procedure parameters.
Final Table with joined temp tables

<details>
<summary>Code Snippet</summary>

```sql

/*
Final Query Output that joins the Products, Sales Order, & the Ship To & Bill To Temp Tables
*/


-----------------------------------------------------------------------------------------------------
/*
Final Query Output that joins the Products, Sales Order, & the Ship To & Bill To Temp Tables
*/


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
		((SOT.OrderDate between @StartDate and @EndDate) or (SOT.OrderDate is null)) --Captures items in date range and items with no sales

--AND Conditions to handle multiple items or ALL items in the WHERE clause
	and
		(isnull(P.[ProductNumber],'') in(select ItemNumber from #ItemNumberWildcardLoop) or '' in(select ItemNumber from #ItemNumberWildcardLoop) )
	and
		(isnull(P.[Subcategory Name],'') in(@ProductSubcategory) or '' in(@ProductSubcategory) )
	and
		(isnull(P.[Category Name],'') in(@ProductCategory) or '' in(@ProductCategory) )
	and
		(isnull(SOT.[CustomerID],'') in(@CustAccountNumber) or '' in (@CustAccountNumber)  )


--Wildcard searches that return all values when empty string is passed to a variable.
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


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
drop all the temp tables in the stored procedure
*/

drop table #ItemNumberWildcardLoop
drop table #ItemNumber
drop table #ItemNumberWithPK
drop table #SalesOrderTable
drop table #CustomersTable
drop table #ProductsTable





```
</details>

## f. Connect to AdventureWorks2019 database in SSRS Report.
## g. Connect to stored procedure in SSRS Report.
## h. Modify the report parameters to allow only the correct values.
## i. Format the report.
## j. Publish the Report.

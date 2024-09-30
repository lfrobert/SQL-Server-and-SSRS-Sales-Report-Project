exec dbo.[Multi Product Partial Product Search on Sales Order Data SP]

@ProductNumberPar = 'BA%,BB%,BE%,BK-R93R-62,FR-____-60,%-1000,%-[4-5][0-2]'
--@ProductNumberPar = '%'

,@StartDate = '2011-05-31'
,@EndDate = '2014-06-30'


,@ProductSubcategory = ''
,@ProductCategory = ''
,@CustomerID = ''


,@ShipToAddress = '%'
,@ShipToPostalCode = '%'
,@ShipToLocationType = '%'
,@BillToAddress = '%'
,@BillToPostalCode = '%'
,@BillToLocationType = '%'



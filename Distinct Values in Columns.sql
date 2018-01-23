/*
*****************************************************************************************************************************
WARNING! Please read the comments before running this script!

This script goes through every single column in the database to check how many total and how many distinct values they have.
It is highly recommended to run this query against copy of the production database, rather than the production itself. 
This is because SELECT COUNT f.ex. can cause blocking, as it scans through the tables.

*****************************************************************************************************************************
*/

USE tempdb;
GO
IF EXISTS (SELECT name FROM sys.tables WHERE name = 'ColumnReport')
    DROP TABLE ColumnReport;
GO
CREATE TABLE dbo.ColumnReport -- Note that this is an actual table, you should remove it once you don't need it anyomre
(
    tableName VARCHAR(100),
    columnName VARCHAR(100),
    totalRows INT,
	distinctRows INT,
	pctDistinct AS (distinctRows * 100)/ NULLIF(totalRows,0) -- Calculated column to show distinct percentages, NULLIF handles divide by zero
);
GO
USE Database_X --Change the database name here
GO
DECLARE @tblName VARCHAR(40);
DECLARE @clmName VARCHAR(40);
DECLARE @countTotal INT;
DECLARE @countDistinct INT;
DECLARE @sqlStatement NVARCHAR(800)

DECLARE DistinctValueCount CURSOR FOR
SELECT t.name,
	   c.name  FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id

OPEN DistinctValueCount;

FETCH NEXT FROM DistinctValueCount
INTO @tblName,
     @clmName;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @sqlStatement
        = 'SELECT @countTotal=COUNT(' + @clmName + '), @countDistinct=COUNT(DISTINCT '+ @clmName +') FROM ' + @tblName +'';
    EXEC sp_executesql @sqlStatement,
                       @Params = N'@countTotal INT OUTPUT, @countDistinct INT OUTPUT',
                       @countTotal = @countTotal OUTPUT,
					   @countDistinct = @countDistinct OUTPUT;
    INSERT INTO tempdb..ColumnReport -- Create the row report
    (
        tableName,
        columnName,
        totalRows,
		distinctRows
    )
    VALUES
    (@tblName,
     @clmName,
     @countTotal,
	 @countDistinct
    );
    FETCH NEXT FROM DistinctValueCount
    INTO @tblName,
         @clmName;
END;

-- Clean up

CLOSE DistinctValueCount;
DEALLOCATE DistinctValueCount;
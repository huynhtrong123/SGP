-- Define the target values
DECLARE @TargetQuantity INT = {{Workflow.Properties.quantity}};
DECLARE @TargetIterations INT = {{Workflow.Properties.item.count}};

-- Temporary table to store original query results
CREATE TABLE #TempDR (
    ID INT,
    PO_NUMBER VARCHAR(50),
    DUE_DATE DATE,
    PO_ROLL INT,
    PRODUCT VARCHAR(100),
    WIDTH FLOAT,
    WEIGHT INT,
    CUSTOMER VARCHAR(50),
    CREATED_DATE DATETIME,
    CREATED_BY VARCHAR(50),
    IS_PROCESSED BIT,
    IS_DELETED BIT,
    PRIORITY INT,
    TOTAL_ROLL INT
);

-- Insert data from the original query into #TempDR
INSERT INTO #TempDR
SELECT
    DR.*,
    DR.PO_ROLL - ISNULL(PROD.TOTAL, 0) AS TOTAL_ROLL
FROM
    SGP.DBO.DELIVERY_REQUEST DR
OUTER APPLY (
    SELECT SUM(ISNULL(PS.ROLL_QUANTITY, 0)) AS TOTAL
    FROM SGP.DBO.PRODUCTION_SCHEDULE PS
    WHERE
        PS.PO_NUMBER = DR.PO_NUMBER AND PS.UNIT_WEIGHT = DR.WEIGHT AND PS.WIDTH = DR.WIDTH AND PS.[OPTION] = '4'
) PROD
WHERE
    DR.PRODUCT LIKE '{{Workflow.Properties.product}}%' AND DR.WEIGHT = {{Workflow.Properties.weight}} AND DR.WIDTH = {{Workflow.Properties.item.decimal}} AND DR.PO_ROLL > ISNULL(PROD.TOTAL, 0)
ORDER BY DR.PRIORITY ASC;

-- Temp table to store results of each iteration
CREATE TABLE #IterationResults (
    Iteration INT,
    ID INT,
    PO_NUMBER VARCHAR(50),
    DUE_DATE DATE,
    PO_ROLL INT,
    PRODUCT VARCHAR(100),
    WIDTH FLOAT,
    WEIGHT INT,
    CUSTOMER VARCHAR(50),
    CREATED_DATE DATETIME,
    CREATED_BY VARCHAR(50),
    IS_PROCESSED BIT,
    IS_DELETED BIT,
    PRIORITY INT,
    TOTAL_ROLL INT
);

-- Loop through the target number of iterations
DECLARE @Iteration INT = 1;
WHILE @Iteration <= @TargetIterations
BEGIN
    DECLARE @RunningTotal INT = 0;
    DECLARE @LastRowID INT = NULL;
    DECLARE @Leftover INT = 0;

    -- Select rows for the current iteration, accumulating the TOTAL_ROLL until reaching @TargetQuantity
    DECLARE IterCursor CURSOR FOR
        SELECT ID, TOTAL_ROLL
        FROM #TempDR
        WHERE TOTAL_ROLL > 0
        ORDER BY PRIORITY ASC;

    OPEN IterCursor;
    FETCH NEXT FROM IterCursor INTO @LastRowID, @Leftover;

    WHILE @@FETCH_STATUS = 0 AND @RunningTotal < @TargetQuantity
    BEGIN
        IF @RunningTotal + @Leftover > @TargetQuantity
        BEGIN
            -- Insert a partial row to reach exactly the target quantity
            INSERT INTO #IterationResults
            SELECT @Iteration, ID, PO_NUMBER, DUE_DATE, PO_ROLL, PRODUCT, WIDTH, WEIGHT,
                   CUSTOMER, CREATED_DATE, CREATED_BY, IS_PROCESSED, IS_DELETED, PRIORITY,
                   @TargetQuantity - @RunningTotal AS TOTAL_ROLL
            FROM #TempDR WHERE ID = @LastRowID;

            -- Update leftover in #TempDR
            UPDATE #TempDR SET TOTAL_ROLL = @Leftover - (@TargetQuantity - @RunningTotal)
            WHERE ID = @LastRowID;

            SET @RunningTotal = @TargetQuantity;
        END
        ELSE
        BEGIN
            -- Insert the full row
            INSERT INTO #IterationResults
            SELECT @Iteration, ID, PO_NUMBER, DUE_DATE, PO_ROLL, PRODUCT, WIDTH, WEIGHT,
                   CUSTOMER, CREATED_DATE, CREATED_BY, IS_PROCESSED, IS_DELETED, PRIORITY,
                   TOTAL_ROLL
            FROM #TempDR WHERE ID = @LastRowID;

            SET @RunningTotal += @Leftover;

            -- Remove the row from #TempDR
            DELETE FROM #TempDR WHERE ID = @LastRowID;
        END

        -- Fetch the next row
        FETCH NEXT FROM IterCursor INTO @LastRowID, @Leftover;
    END

    CLOSE IterCursor;
    DEALLOCATE IterCursor;

    -- Move to the next iteration
    SET @Iteration += 1;
END

-- Final output: Show results from #IterationResults
SELECT * FROM #IterationResults ORDER BY Iteration, PRIORITY;

-- Clean up temporary tables
DROP TABLE #TempDR;
DROP TABLE #IterationResults;

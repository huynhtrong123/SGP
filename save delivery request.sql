INSERT INTO SGP.DBO.DELIVERY_REQUEST (
    PO_NUMBER,
    DUE_DATE,
    PO_ROLL,
    PRODUCT,
    WEIGHT,
    WIDTH,
    CUSTOMER,
    CREATED_DATE,
    CREATED_BY,
    IS_PROCESSED,
    IS_DELETED,
    NOTE,
    SHIPPING_MARK,
    PRIORITY_DAY,
    PRIORITY
)
VALUES (
    '{{Workflow.Properties.data[0]}}',
    CAST('{{Workflow.Properties.data[1]}}' AS DATETIME),  -- Ensure valid date format
    {{Workflow.Properties.data[2]}},  -- Assuming PO_ROLL is INT
    '{{Workflow.Properties.data[3]}}',
    '{{Workflow.Properties.data[4]}}',
    '{{Workflow.Properties.data[5]}}',
    N'{{Workflow.Properties.data[6]}}',  -- Assuming CUSTOMER is NVARCHAR
    GETDATE(),  -- Automatically sets created date
    'admin',  -- Default user
    0,  -- IS_PROCESSED (Assuming INT)
    0,  -- IS_DELETED (Assuming INT)
    N'{{Workflow.Properties.data[7]}}',  -- Assuming NOTE is NVARCHAR
    N'{{Workflow.Properties.data[8]}}',  -- Assuming SHIPPING_MARK is NVARCHAR
    CASE 
        WHEN '{{Workflow.Properties.data[9]}}' IS NULL OR '{{Workflow.Properties.data[9]}}' = '' 
        THEN NULL
        ELSE CAST('{{Workflow.Properties.data[9]}}' AS DATE)
    END,  -- Ensure NULL instead of 1900-01-01
    {{Workflow.Properties.data[10]}}  -- Assuming PRIORITY is INT
);

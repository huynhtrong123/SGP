DECLARE @CHECKLIST_MAPPING_ID int,
        @TICKET_ID int;

SET @CHECKLIST_MAPPING_ID = 4943;
SET @TICKET_ID = 2154;

SELECT
    cc.ID AS CHECKLIST_ID,
    cci.NAME AS ITEMNAME,
    ccc.NAME AS COLNAME,
    ccv.VALUE as Content_ID
FROM UEIOS_V4_DEMO.dbo.CHK_CHECKLIST cc
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_TEMPLATE cct 
    ON cc.CHECKLIST_TEMPLATE_LINK_ID = cct.ID 
    AND ISNULL(cct.IS_DELETED, 0) = 0
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_MAPPING ccm 
    ON ccm.CHECKLIST_LINK_ID = cc.ID 
    AND ISNULL(ccm.IS_DELETED, 0) = 0
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_GROUP ccg 
    ON ccg.CHECKLIST_TEMPLATE_LINK_ID = cct.ID 
    AND ISNULL(ccg.IS_DELETED, 0) = 0
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_MAPPING_GROUP ccmg 
    ON ccmg.CHECKLIST_MAPPING_LINK_ID = ccm.ID 
    AND ccmg.CHECKLIST_GROUP_LINK_ID = ccg.ID 
    AND ISNULL(ccmg.IS_DELETED, 0) = 0
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_MAPPING_ITEM ccmi 
    ON ccmi.CHECKLIST_MAPPING_GROUP_LINK_ID = ccmg.ID 
    AND ISNULL(ccmi.IS_DELETED, 0) = 0
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_ITEM cci 
    ON cci.ID = ccmi.CHECKLIST_ITEM_LINK_ID 
    AND cci.CHECKLIST_GROUP_LINK_ID = ccg.ID 
    AND ISNULL(cci.IS_DELETED, 0) = 0 
  
JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_COLUMN ccc 
    ON cci.CHECKLIST_GROUP_LINK_ID = ccg.ID 
    AND ccc.CHECKLIST_TEMPLATE_LINK_ID = cct.ID 
    AND ISNULL(ccc.IS_DELETED, 0) = 0 
  
LEFT JOIN UEIOS_V4_DEMO.dbo.CHK_CHECKLIST_VALUE ccv 
    ON ccv.CHECKLIST_COLUMN_LINK_ID = ccc.ID 
    AND ccv.CHECKLIST_ITEM_LINK_ID = cci.ID 
    AND ccv.CHECKLIST_MAPPING_ITEM_LINK_ID = ccmi.ID
JOIN UEIOS_V4_DEMO.dbo.ISM_ISSUE_CHECKLIST IIC 
    ON IIC.CHECKLIST_MAPPING_ID = ccm.ID
JOIN UEIOS_V4_DEMO.dbo.ISM_ISSUE II 
    ON II.ID = IIC.ISSUE_LINK_ID
WHERE ISNULL(cc.IS_DELETED, 0) = 0
    AND ccm.ID = @CHECKLIST_MAPPING_ID
    AND II.ID = @TICKET_ID
	and  cci.NAME = 'Request File'

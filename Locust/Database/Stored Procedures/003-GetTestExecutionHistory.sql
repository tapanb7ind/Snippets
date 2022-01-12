USE `perf-api`;
DROP procedure IF EXISTS `GetTestExecutionHistory`;

DELIMITER $$
USE `perf-api`$$
CREATE DEFINER=`root`@`%` PROCEDURE `GetTestExecutionHistory`(
	IN testid INT)
BEGIN	
	SELECT 
      T2.id
	, T1.id as 'testid'
    , T1.uuid
    , T1.description
    , T3.status
    , T3.description as 'statusdescription'
    , CASE WHEN T3.Status NOT IN ('NONE','COMPLETED') THEN 1 ELSE 0 END AS CanRefresh
    , CASE WHEN T3.Status IN ('QUEUED', 'LOOKUPAGENT', 'INITIATING','RUNNING') THEN 1 ELSE 0 END AS CanStop
    , CASE WHEN T3.Status IN ('COMPLETED') THEN 1 ELSE 0 END AS CanRerun
    , CASE
		WHEN T3.status IN ('RUNNING', 'INITIATING') THEN T4.description
        WHEN T3.status = 'QUEUED' THEN 'Queued'
        WHEN T3.status = 'LOOKUPAGENT' THEN 'Finding Agent'
        WHEN T3.status IN ('PRETEST', 'SAVING', 'COMPLETED') THEN T3.description
        END AS 'SubStatus'
    , T2.created 'LastUpdated'
    , T1.createdby 'RequestedBy'    
    FROM TestRequestQueue T1
	INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
	INNER JOIN TestStatusR T3 ON T2.statusid = T3.id
    RIGHT JOIN TestSubStatusR T4 ON T2.substatusid = T4.id
    -- WHERE testid IS NULL OR T1.id=testid
    WHERE T1.id=testid AND T1.id IS NOT NULL
    ORDER BY T3.id DESC, T2.created;
END$$

DELIMITER ;

-- Examples
CALL GetTestExecutionHistory(1);
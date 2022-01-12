USE `perf-api`;
DROP procedure IF EXISTS `GetTestSummary`;

USE `perf-api`;
DROP procedure IF EXISTS `perf-api`.`GetTestSummary`;
;

DELIMITER $$
USE `perf-api`$$
CREATE DEFINER=`root`@`%` PROCEDURE `GetTestSummary`(
	IN Offset INT,
    IN PageSize INT)
BEGIN
	IF PageSize > 1000 THEN		
        SET PageSize = 1000;		-- Limit to 1000 rows ONLY
    END IF;    
	SELECT 
	  T1.id as 'testid'
    , T2.id  
    , T1.uuid
    , T1.description as 'description'
    , T3.status
    , T3.description AS 'statusdescription'
    , CASE
		WHEN T3.status IN ('RUNNING', 'INITIATING') THEN T4.description
        WHEN T3.status = 'QUEUED' THEN 'Queued'
        WHEN T3.status = 'LOOKUPAGENT' THEN 'Finding Agent'
        WHEN T3.status IN ('PRETEST', 'SAVING', 'COMPLETED') THEN T3.description
        END AS 'SubStatus'
	, CASE 
		WHEN T3.status IN ('SAVING', 'COMPLETED', 'STOPPED', 'STOPPING', 'STOP', 'FAILED') THEN 0
        WHEN T3.status IN ('RUNNING', 'INITIATING', 'QUEUED') THEN 1
        WHEN T3.status NOT IN  ('SAVING', 'COMPLETED', 'STOPPED', 'STOPPING', 'STOP', 'RUNNING', 'INITIATING', 'QUEUED', 'FAILED') THEN 0
		END AS 'CanStop'
	, CASE 
		WHEN T3.status IN ('SAVING', 'COMPLETED', 'STOPPED', 'STOPPING', 'STOP') THEN 1 ELSE 0        
		END AS 'CanRerun'
	, CASE
		WHEN T3.status NOT IN  ('STOPPED', 'STOPPING', 'STOP', 'COMPLETED', 'FAILED') THEN 1 ELSE 0 END AS 'CanRefresh'
    , T2.created 'LastUpdated'
    , T1.createdby 'RequestedBy'    
    FROM TestRequestQueue T1
	INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
	LEFT JOIN TestStatusR T3 ON T2.statusid = T3.id
    RIGHT JOIN TestSubStatusR T4 ON T2.substatusid = T4.id 
    WHERE(testid, T2.created) IN (SELECT testid, MAX(created) FROM TestStatusHistory GROUP BY testid)    
	LIMIT PageSize, Offset;
END

/*
Example:
-- 1st page
call GetTestSummary(25, 1);
-- 2nd page
call GetTestSummary(50, 26);
*/

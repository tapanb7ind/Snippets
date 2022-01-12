USE `perf-api`;
DROP procedure IF EXISTS `GetNextTestRequest`;

USE `perf-api`;
DROP procedure IF EXISTS `perf-api`.`GetNextTestRequest`;
;

DELIMITER $$
USE `perf-api`$$
CREATE DEFINER=`root`@`%` PROCEDURE `GetNextTestRequest`(
	IN AgentId INT)
BEGIN
	SET @testid = 0;
    SET @status_initiating = 'INITIATING';
    SET @substatus_none = 'NONE';
    
		SELECT 
		  T1.id INTO @testid
		FROM TestRequestQueue T1
		INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
		INNER JOIN TestStatusR T3 ON T2.statusid = T3.id
		RIGHT JOIN TestSubStatusR T4 ON T2.substatusid = T4.id 
		WHERE(testid, T2.created) IN (SELECT testid, MAX(created) FROM TestStatusHistory GROUP BY testid)
		AND T3.status IN ('QUEUED', 'LOOKUPAGENT')
		ORDER BY T1.id ASC LIMIT 1;
		
        IF @testid > 0 THEN
			START TRANSACTION;
				-- SELECT id INTO @status_initiating FROM TestStatusR WHERE status='INITIATING';
				-- SELECT id INTO @substatus_none FROM TestSubStatusR WHERE status='NONE';			
				INSERT INTO AgentTestHistory (agentid, testid) VALUES (AgentId, @testid);
				CALL setteststatus(@testid, @status_initiating, @substatus_none, 0);
				-- SELECT T1.id, T1.uuid, T1.description 'description', T1.createdby, T1.created, T1.modifiedby, T1.modified FROM TestRequestQueue T1 WHERE T1.id=@testid;                
			COMMIT;
		ELSE 
			SET @testid = 0;
        END IF;    
        
        SELECT @testid 'testid';    
END$$

DELIMITER ;
;


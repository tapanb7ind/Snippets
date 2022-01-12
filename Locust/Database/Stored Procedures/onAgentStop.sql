USE `perf-api`;
DROP procedure IF EXISTS `onStopAgent`;

USE `perf-api`;
DROP procedure IF EXISTS `perf-api`.`onStopAgent`;
;

DELIMITER $$
USE `perf-api`$$
CREATE DEFINER=`root`@`%` PROCEDURE `onStopAgent`(
		IN AgentId INT,
        IN agentstatus VARCHAR(100)
	)
BEGIN		
    -- SET @agentStatus = 'STOPPING';
    SET @agentStatusId = 0;
    SET @lastStatusId = 0;
    SET @agentfound = 0;
    -- SELECT @AgentId, @agentstatus;
    
    SELECT COUNT(*) INTO @agentfound FROM Agents T1 WHERE T1.id=AgentId; 
    
    SELECT id INTO @agentStatusId FROM AgentStatusR WHERE `status`= agentStatus;
    SELECT T1.id INTO @lastStatusId FROM AgentStatusHistory T1 WHERE T1.agentid = AgentId AND T1.agentstatusid=@lastStatusId
    AND (agentid, agentstatusid) IN (SELECT agentid, MAX(created) FROM AgentStatusHistory);
    -- SELECT @lastStatusId AS 'laststatus'; 
    IF @agentfound = 1 AND @lastStatusId = 0 AND @agentStatusId > 0 THEN
		START TRANSACTION;
			UPDATE Agents T1 SET T1.status=agentStatus, T1.stopflag=1, T1.modified=utc_timestamp() WHERE T1.id=AgentId;
			INSERT INTO AgentStatusHistory (agentid, agentstatusid) values (AgentId, @agentStatusId);
        COMMIT;
	END IF;
    SELECT T1.* FROM Agents T1 WHERE T1.id=AgentId; 
END$$

DELIMITER ;
;


-- Examples:
-- CALL onStopAgent(3, 'STOPPING');
-- CALL onStopAgent(3, 'STOPPED');

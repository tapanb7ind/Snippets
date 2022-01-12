
USE `perf-api`;
DROP procedure IF EXISTS `onAgentStartUp`;

USE `perf-api`;
DROP procedure IF EXISTS `perf-api`.`onAgentStartUp`;
;

DELIMITER $$
USE `perf-api`$$

CREATE PROCEDURE `onAgentStartUp` (
		IN `name` VARCHAR(255),
		IN ipaddr VARCHAR(255),
        IN version VARCHAR(255)
	)
BEGIN	
	SET @agentId = 0;    
    SET @agentStatus = 'STARTING';
    SET @agentStatusId = 0;
    SELECT id INTO @agentStatusId FROM AgentStatusR WHERE `status`=@agentStatus;
    
    IF @agentStatusId > 0 THEN
		START TRANSACTION;
			SELECT id INTO @agentId FROM Agents WHERE hostname=`name` AND ipaddr=ipaddr;
			IF @agentId > 0 THEN		
				UPDATE Agents SET hostname=`name`, ipaddr=ipaddr, `status`=@agentStatus, stopflag=0, modified=utc_timestamp() WHERE id=@agentId;
			ELSE 
				INSERT INTO Agents (hostname, ipaddr, codeversion, status, stopflag)
					VALUES (`name`, ipaddr, version, 'STARTING', 0);
				SELECT id INTO @agentId FROM Agents WHERE hostname=`name` AND ipaddr=ipaddr;				
			END IF;		
		
			IF @agentId > 0 THEN
				INSERT INTO AgentStatusHistory (agentid, agentstatusid) values (@agentId, @agentStatusId);
				SELECT * FROM Agents WHERE id=@agentId;
			END IF;
        COMMIT;
	END IF;
END;

-- Examples:
CALL onAgentStartUp('localhost1','12.1.1.1','1.0.0');

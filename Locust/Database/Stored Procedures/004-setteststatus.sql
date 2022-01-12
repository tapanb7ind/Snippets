USE `perf-api`;
DROP procedure IF EXISTS `setteststatus`;

DELIMITER $$
USE `perf-api`$$
CREATE PROCEDURE `setteststatus` (
	IN testid INT, 
    IN status VARCHAR(50), 
    IN substatus VARCHAR(50),
    IN showresult BIT) 
BEGIN

	/*
    
    REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 2, 6);	-- LOOKUPAGENT
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 3, 6);	-- INITIATING
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 4, 6);	-- PRETEST
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 5, 1);	-- RUNNING, initializing
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 5, 2);	-- RUNNING, running
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 5, 4);	-- RUNNING, merging
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 5, 5);	-- RUNNING, saving
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 6, 6);	-- SAVING
	REPLACE INTO `perf-api`.`TestStatusHistory` (testid, statusid, substatusid) VALUES (1, 7, 6);	-- COMPLETED
    
    Example:
		CALL setteststatus(2, 'LOOKUPAGENT', 'NONE', 1);
		CALL setteststatus(2, 'INITIATING', 'NONE', 1);
		CALL setteststatus(2, 'PRETEST','NONE', 1);
		CALL setteststatus(2, 'RUNNING','INITIALIZING', 1);
		CALL setteststatus(2, 'RUNNING','RUNNING', 1);
		CALL setteststatus(2, 'RUNNING','MERGING', 1);
    
    */
    DECLARE statusid INT;
    DECLARE substatusid INT;
    SELECT id INTO statusid FROM TestStatusR T1 WHERE T1.status=status;
    SELECT id INTO substatusid FROM TestSubStatusR T1 WHERE T1.status=substatus;
    
    IF statusid < 1 THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Invalid Status Provided';
	ELSEIF substatusid < 1 THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Invalid Substatus provided';
	ELSE
		REPLACE INTO `perf-api`.`TestStatusHistory` (`testid`, `statusid`, `substatusid`) VALUES (testid, statusid, substatusid);
        IF showresult THEN
			SELECT * FROM `perf-api`.`TestStatusHistory` T1 WHERE T1.testid = testid AND T1.statusid=statusid AND T1.substatusid = substatusid;
		END IF;
	END IF;

END$$

DELIMITER ;


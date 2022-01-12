-- CREATE SCHEMA `perf-api` ;
USE `perf-api`;

CREATE TABLE IF NOT EXISTS `perf-api`.`TestRequestQueue` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL DEFAULT (uuid()),
  `description` VARCHAR(255) NOT NULL,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`));
    
CREATE TABLE IF NOT EXISTS `perf-api`.`TestParameters` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `testid` INT NOT NULL ,
  `testparams` JSON NOT NULL DEFAULT ('{}'),
  `toolparams` JSON NOT NULL DEFAULT ('{}'),
  `tooltype` VARCHAR(255) NOT NULL DEFAULT ('locust'),
  `toolversion` VARCHAR(255) NOT NULL DEFAULT ('2.5'),
  `workflowid` INT NOT NULL,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`),
  FOREIGN KEY (testid)
	REFERENCES TestRequestQueue (id)
    ON UPDATE RESTRICT ON DELETE CASCADE
  );
  
ALTER TABLE `perf-api`.`TestParameters` 
ADD COLUMN `workflowid` INT NOT NULL AFTER `toolversion`;
ALTER TABLE `perf-api`.`TestParameters` 
ADD CONSTRAINT `TestParameters_ibfk_2`
  FOREIGN KEY (workflowid)
  REFERENCES `perf-api`.`WorkflowDesigns` (id)
  ON DELETE RESTRICT
  ON UPDATE RESTRICT;


CREATE TABLE `TestStatusR` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL DEFAULT (uuid()),
  `status` varchar(45) NOT NULL,
  `canstop` BIT NOT NULL DEFAULT 0,
  `description` varchar(255) NOT NULL,
  `createdby` varchar(255) NOT NULL,
  `created` timestamp NOT NULL DEFAULT (utc_timestamp()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid_UNIQUE` (`uuid`),
  UNIQUE KEY `status_UNIQUE` (`status`)
); -- ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `perf-api`.`TestStatusR` 
ADD COLUMN `modified` TIMESTAMP NULL DEFAULT (utc_timestamp()); 

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='QUEUED',
		`canstop`=1,
		`description` = 'Test is queued',
        `createdby`='system';

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='LOOKUPAGENT',
		`canstop`=1,
		`description` = 'Checking available agents',
        `createdby`='system';       

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='INITIATING',
		`canstop`=1,
		`description` = 'Test is initializing',
        `createdby`='system';

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='PRETEST',
		`canstop`=1,
		`description` = 'Executing pre-test task(s)',
        `createdby`='system';
        
INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='RUNNING',
		`canstop`=1,
		`description` = 'Test is in progress',
        `createdby`='system';

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='SAVING',
		`canstop`=0,
		`description` = 'Saving/merging results',
        `createdby`='system';

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='COMPLETED',
		`canstop`=0,
		`description` = 'Test Completed',
        `createdby`='system';
        
INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='NONE',
		`canstop`=0,
		`description` = 'No Status',
        `createdby`='system';

INSERT IGNORE INTO `perf-api`.`TestStatusR`
	SET `status`='STOPPED',
		`canstop`=0,
		`description` = 'Test Stopped by user',
        `createdby`='system';
        
SELECT id, status, description FROM `perf-api`.`TestStatusR`;
-- UPDATE `perf-api`.`TestStatusR` SET requestedby='system' WHERE id > 0; 

CREATE TABLE IF NOT EXISTS `perf-api`.`TestSubStatusR` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `teststatusid` INT NOT NULL,
  `status` VARCHAR(255) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`),
  FOREIGN KEY (teststatusid)
	REFERENCES TestStatusR (id)
    ON UPDATE RESTRICT ON DELETE CASCADE );

INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (5, 'initializing','Agent is assigned and test is now initializing');

INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (5, 'running','Test is in progress');
    
INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (5, 'stopping','Test Stop request received from user');
    
INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (5, 'merging','Test completed, merging/collecting results');
    
INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (5, 'saving','Test completed, saving results');

INSERT IGNORE INTO `perf-api`.`TestSubStatusR` (teststatusid, status, description)
	VALUES (8, 'none','No status');
    
SELECT id, teststatusid, status, description FROM `perf-api`.`TestSubStatusR` ORDER BY id ASC;
  
CREATE TABLE IF NOT EXISTS `perf-api`.`TestStatusHistory` (
  `id` INT NOT NULL AUTO_INCREMENT,  
  `testid` INT NOT NULL,
  `statusid` INT NOT NULL,
  `substatusid` INT NOT NULL DEFAULT 1,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`),
  FOREIGN KEY (statusid)
	REFERENCES TestStatusR (id),
  FOREIGN KEY (substatusid)
	REFERENCES TestSubStatusR (id),
  FOREIGN KEY (testid)
	  REFERENCES TestRequestQueue (id));
      

ALTER TABLE `perf-api`.`TestStatusHistory` ADD UNIQUE `testid_statusid_substatusid` (`statusid`, `testid`, `substatusid`);

      

CREATE TABLE IF NOT EXISTS `perf-api`.`Agents` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL DEFAULT (uuid()),
  `hostname` VARCHAR(255) NOT NULL,
  `ipaddr` VARCHAR(255) NOT NULL,  
  `codeversion` VARCHAR(255) NOT NULL,
  `status` VARCHAR(100) NOT NULL DEFAULT 'AVAILABLE',  
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`));

CREATE TABLE IF NOT EXISTS `perf-api`.`AgentStatusHistory` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`agentid` INT NOT NULL,
    `agentstatusid` INT NOT NULL,
	`createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
	`created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
	`modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
	`modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id` DESC),
  FOREIGN KEY (agentid)
	REFERENCES Agents (id),
  FOREIGN KEY (agentstatusid)
	REFERENCES AgentStatusR (id)
  );
  
ALTER TABLE `perf-api`.`AgentStatusHistory` 
ADD INDEX `agentid_statusid_created` (`created` DESC, `agentid` ASC, `agentstatusid` ASC) VISIBLE;
;

CREATE TABLE IF NOT EXISTS `perf-api`.`AgentStatusR` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `status` VARCHAR(255) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`));
  
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('STARTING','Agent is starting');

INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('AVAILABLE','Agent is available to execute test');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('RUNNING','Agent is executing a test');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('WAITING','Agent is waiting for input');

INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('UNKNOWN','Agent status is unknown');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('RESTART','Agent is restarting');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('STOPPING','Agent is marked to stop');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('STOPPED','Agent is stopped');
    
INSERT IGNORE INTO `perf-api`.`AgentStatusR` (status, description)
	VALUES ('BUSY','Agent is running a test');
    
-- DROP TABLE `perf-api`.`AgentStatusR`;    
SELECT * FROM `perf-api`.`AgentStatusR`;

CREATE TABLE IF NOT EXISTS `perf-api`.`AgentTestHistory` (
  `id` INT NOT NULL AUTO_INCREMENT,  
  `agentid` INT NOT NULL,
  `testid` INT NULL,
  `assignedat` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id` DESC),
  FOREIGN KEY (agentid)
	REFERENCES Agents (id),
  FOREIGN KEY (testid)
	REFERENCES TestRequestQueue (id)
  );  
  
CREATE TABLE IF NOT EXISTS `perf-api`.`AgentPingActivity` (
  `id` INT NOT NULL AUTO_INCREMENT,  
  `agentid` INT NOT NULL,
  `ipaddr` VARCHAR(255) NOT NULL,
  `codeversion` VARCHAR(255) NOT NULL,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id`),
  FOREIGN KEY (agentid)
	REFERENCES Agents (id)
    ON UPDATE RESTRICT ON DELETE CASCADE
  );  
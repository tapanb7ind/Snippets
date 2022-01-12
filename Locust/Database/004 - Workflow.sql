CREATE TABLE IF NOT EXISTS `perf-api`.`WorkflowDesigns` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL DEFAULT (uuid()),
  `name` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `duration` INTEGER NOT NULL DEFAULT 5,
  `total_users` INTEGER NOT NULL DEFAULT 5,
  `spawn_users` INTEGER NOT NULL DEFAULT 1,
  `json` TEXT NOT NULL,
  `isvalid` BIT NOT NULL DEFAULT 0,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id` DESC));
  
ALTER TABLE `perf-api`.`WorkflowDesigns` 
ADD UNIQUE INDEX `name` (`name` ASC) VISIBLE;
;

SELECT * FROM WorkflowDesigns;

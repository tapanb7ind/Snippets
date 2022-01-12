CREATE TABLE IF NOT EXISTS `perf-api`.`ConfiguredApi` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL DEFAULT (uuid()),
  `name` VARCHAR(50) NOT NULL,
  `displayname` VARCHAR(50) NOT NULL,
  `endpoint` VARCHAR(100) NOT NULL DEFAULT '',
  `method` VARCHAR(50) NOT NULL DEFAULT 'GET',
  `description` VARCHAR(255) NOT NULL,
  `defaults` TEXT NULL,
  `usersallowed` INT NULL DEFAULT 15,
  `isvalid` BIT NOT NULL DEFAULT 1,
  `createdby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `created` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  `modifiedby` VARCHAR(255) NOT NULL DEFAULT ('system'),
  `modified` TIMESTAMP NOT NULL DEFAULT (UTC_TIMESTAMP),
  PRIMARY KEY (`id` DESC));
  
ALTER TABLE `perf-api`.`ConfiguredApi` 
ADD UNIQUE INDEX `unique_name` (`name` ASC) VISIBLE,
ADD UNIQUE INDEX `unique_endpoint` (`endpoint` ASC) VISIBLE;

SELECT * FROM ConfiguredApi;


USE `perf-api`;
DROP procedure IF EXISTS `newrequest`;

USE `perf-api`;
DROP procedure IF EXISTS `perf-api`.`newrequest`;
;

DELIMITER $$
USE `perf-api`$$
CREATE DEFINER=`root`@`%` PROCEDURE `newrequest`(
		IN testdescription VARCHAR(255),
		IN requestedBy VARCHAR(255)
	)
BEGIN
	DECLARE testid INT DEFAULT 0;
    DECLARE testuuid VARCHAR(255) DEFAULT (uuid());
    
	INSERT INTO `perf-api`.`TestRequestQueue` (uuid, description, createdby)
		VALUES (testuuid, testdescription, requestedBy);
	
    SELECT id INTO testid FROM `perf-api`.`TestRequestQueue` WHERE uuid = testuuid AND description=testdescription AND createdby=requestedBy;
    
    IF testid > 0 THEN		
        REPLACE INTO `perf-api`.`TestStatusHistory` (`testid`, `statusid`, `substatusid`) VALUES (testid, 1, 1);
        SELECT * FROM `perf-api`.`TestRequestQueue` WHERE id = testid;
    END IF;
END$$

DELIMITER ;
;


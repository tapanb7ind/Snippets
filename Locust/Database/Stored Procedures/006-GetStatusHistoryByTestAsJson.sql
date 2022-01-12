USE `perf-api`;
DROP procedure IF EXISTS `GetStatusHistoryByTestAsJson`;

DELIMITER $$
USE `perf-api`$$
CREATE PROCEDURE `GetStatusHistoryByTestAsJson` (
IN testid int)
BEGIN
	SELECT T.id, T.description, T.createdby, T.created,
       JSON_OBJECT('statuses',
           (SELECT JSON_ARRAYAGG(JSON_OBJECT(
               'id', T1.id,
               'status', T2.status,
               'substatus', T3.status,
               'created', T1.created )) `StatusHistory`
                FROM TestStatusHistory T1
                         INNER JOIN TestStatusR T2 on T1.statusid = T2.id
                         INNER JOIN TestSubStatusR T3 on T1.substatusid = T3.id
                WHERE T1.testid = T.id                
                GROUP BY testid))
	FROM TestRequestQueue T
    WHERE T.id=testid OR testid=0;
END$$

DELIMITER ;

/*
Example
call `perf-api`.GetStatusHistoryByTestAsJson(0); -> Get all rows 
call `perf-api`.GetStatusHistoryByTestAsJson(22);


*/
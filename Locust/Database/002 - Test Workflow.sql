call GetTestSummary(1,10);
call GetTestSummary(0,10);
call GetTestSummary(25, 3);

-- 1st page
call GetTestSummary(25, 1);
-- 2nd page
call GetTestSummary(50, 26);


select * from Agents;
Select * from AgentPingActivity;
select * from AgentTestHistory;
select * from Users;

SELECT T1.* FROM TestRequestQueue T1 WHERE T1.id=1;

CALL GetNextTestRequest(1);
-- INSERT INTO `perf-api`.`Agents` (hostname, ipaddr, codeversion, status) values ("localhost", "127.0.0.1", "1.0", 1);
/*

This is for illustration purposes ONLY and NOT required to set up as part of project set up

Wipe Data:
	DELETE FROM TestParameters WHERE id > 0;
	DELETE FROM TestStatusHistory WHERE id > 0;
	DELETE FROM TestRequestQueue WHERE id > 0;
    DELETE FROM TestSubStatusR WHERE id > 0;
    DELETE FROM TestStatusR WHERE id > 0;
    
	DELETE FROM Agents WHERE id > 0;
	DELETE FROM AgentsPingActivity WHERE id > 0;

Drop Tables:
	DROP TABLE TestParameters;
	DROP TABLE TestStatusHistory;
	DROP TABLE TestRequestQueue;
    DROP TABLE TestSubStatusR;
    DROP TABLE TestStatusR;
    
    DROP TABLE AgentPingActivity;
    DROP TABLE AgentExecutionStatus;
    DROP TABLE Agents;

*/

CALL GetTestSummary(0, 10);
CALL GetTestExecutionHistory(2);

CALL GetNextTestRequest(1);
/*

TestStatusR:

'1','QUEUED','Test is queued'
'2','LOOKUPAGENT','Checking available agents'
'3','INITIATING','Test is initializing'
'4','PRETEST','Executing pre-test task(s)'
'5','RUNNING','Test is in progress'
'6','SAVING','Saving/merging results'
'7','COMPLETED','Test Completed'
'8','NONE','No Status'

TestSubStatusR:

'1','5','initializing','Agent is assigned and test is now initializing'
'2','5','running','Test is in progress'
'3','5','stopping','Test Stop request received from user'
'4','5','merging','Test completed, merging/collecting results'
'5','5','saving','Test completed, saving results'
'6','8','none','No status'


*/
select * from TestRequestQueue;
select * from TestSubStatusR;
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
*/

CALL GetTestSummary(0, 10);
CALL setteststatus(2, 'LOOKUPAGENT', 'NONE');
CALL setteststatus(2, 'INITIATING', 'NONE');
CALL setteststatus(2, 'PRETEST','NONE');
CALL setteststatus(2, 'RUNNING','INITIALIZING');
CALL setteststatus(2, 'RUNNING','RUNNING');
CALL setteststatus(2, 'RUNNING','MERGING');
CALL setteststatus(2, 'RUNNING','SAVING');
CALL setteststatus(2, 'SAVING','NONE');
CALL setteststatus(2, 'COMPLETED','NONE');

SELECT 
	  T1.id
    , T1.uuid
    , T3.status
    , T3.description
    , CASE
		WHEN T3.status='QUEUED' THEN 'Queued' ELSE T4.description END AS 'SubStatus'
    , T2.created 'LastUpdated'
    , T1.createdby 'RequestedBy'    
    FROM TestRequestQueue T1
	INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
	INNER JOIN TestStatusR T3 ON T2.statusid = T3.id
    RIGHT JOIN TestSubStatusR T4 ON T2.substatusid = T4.id
    WHERE T1.id=1
    ORDER BY T3.id;

SELECT * FROM `perf-api`.`TestRequestQueue`;
-- DELETE FROM `perf-api`.`TestRequestQueue` WHERE id>1;
-- New Request Posted

SELECT * FROM `perf-api`.`TestStatusHistory`;
-- DELETE FROM `perf-api`.`TestStatusHistory` WHERE id>1;
SELECT * FROM `perf-api`.`TestStatusR`;

SELECT T1.id, T1.uuid, T3.status, T3.description, T2.created 'LastUpdated' FROM TestRequestQueue T1
INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
INNER JOIN TestStatusR T3 ON T2.statusid = T3.id ORDER BY T3.id DESC LIMIT 1;

SELECT 
	  T1.id
    , T1.uuid
    , T3.status
    , T3.description    
    , T2.created 'LastUpdated'
    , T1.createdby 'RequestedBy'    
    FROM TestRequestQueue T1
	INNER JOIN TestStatusHistory T2 ON T1.id = T2.testid
	INNER JOIN TestStatusR T3 ON T2.statusid = T3.id
    RIGHT JOIN TestSubStatusR T4 ON T2.substatusid = T4.id 
    WHERE(testid, T2.created) IN (SELECT testid, MAX(created) FROM TestStatusHistory GROUP BY testid)
    AND T3.status IN ('QUEUED', 'LOOKUPAGENT')
    ORDER BY T1.id ASC LIMIT 1;


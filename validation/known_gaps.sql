-- Probes for rules the schema does not enforce. Each probe rolls back, so the data is unchanged.
-- Every probe prints: gap|description|OPEN (the bad change was accepted) or CLOSED (it was blocked).
-- Results are informational and do not fail the validation run.
SET NOCOUNT ON;
GO
BEGIN TRANSACTION;
BEGIN TRY
  UPDATE PROJECTS SET project_start_date='2025-03-01' WHERE project_id=0;
  IF EXISTS (SELECT 1 FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id WHERE t.project_id=0 AND r.record_date<'2025-03-01')
    PRINT 'gap|moving a project start can leave records before the new start|OPEN';
  ELSE PRINT 'gap|moving a project start can leave records before the new start|CLOSED';
END TRY BEGIN CATCH PRINT 'gap|moving a project start can leave records before the new start|CLOSED'; END CATCH;
IF @@TRANCOUNT>0 ROLLBACK;
GO
BEGIN TRANSACTION;
BEGIN TRY
  DELETE FROM TASK_RECORD_BY_ENGINEER WHERE task_id IN (SELECT TOP 1 task_id FROM REVIEWS ORDER BY review_id);
  IF EXISTS (SELECT 1 FROM REVIEWS v WHERE NOT EXISTS (SELECT 1 FROM TASK_RECORD_BY_ENGINEER r WHERE r.task_id=v.task_id))
    PRINT 'gap|deleting records can leave a review with no record behind it|OPEN';
  ELSE PRINT 'gap|deleting records can leave a review with no record behind it|CLOSED';
END TRY BEGIN CATCH PRINT 'gap|deleting records can leave a review with no record behind it|CLOSED'; END CATCH;
IF @@TRANCOUNT>0 ROLLBACK;
GO
BEGIN TRANSACTION;
BEGIN TRY
  INSERT INTO TASK_RECORD_BY_ENGINEER(task_id,employee_id,hours_spent,record_date,result_of_record) VALUES (0,0,1,'2025-02-03',0);
  PRINT 'gap|a Manager not assigned to a task can log an engineer record|OPEN';
END TRY BEGIN CATCH PRINT 'gap|a Manager not assigned to a task can log an engineer record|CLOSED'; END CATCH;
IF @@TRANCOUNT>0 ROLLBACK;
GO
BEGIN TRANSACTION;
BEGIN TRY
  UPDATE TASKS SET task_current_status='Not Started' WHERE task_id=0;
  PRINT 'gap|an approved task with records can return to Not Started|OPEN';
END TRY BEGIN CATCH PRINT 'gap|an approved task with records can return to Not Started|CLOSED'; END CATCH;
IF @@TRANCOUNT>0 ROLLBACK;
GO

-- Negative tests: each statement breaks one business rule and must be blocked by its trigger.
-- Every test prints: trigger|name|expected error|actual error (none = the statement was accepted).
SET NOCOUNT ON;
GO
BEGIN TRY
  INSERT INTO TASKS(employee_id,project_id,task_name,task_priority,task_current_status,task_deadline) VALUES (5,0,'x',1,'Not Started','2030-01-01');
  PRINT 'trigger|trg_task_deadline|50001|none';
END TRY BEGIN CATCH PRINT CONCAT('trigger|trg_task_deadline|50001|',ERROR_NUMBER()); END CATCH;
GO
BEGIN TRY
  INSERT INTO TASK_RECORD_BY_ENGINEER(task_id,employee_id,hours_spent,record_date,result_of_record) VALUES (0,5,1,'2030-01-01',0);
  PRINT 'trigger|trg_record_date|500001|none';
END TRY BEGIN CATCH PRINT CONCAT('trigger|trg_record_date|500001|',ERROR_NUMBER()); END CATCH;
GO
BEGIN TRY
  INSERT INTO REVIEWS(manager_id,task_id,result_of_review,review_date) VALUES (5,0,'Approved','2025-06-01');
  PRINT 'trigger|trg_manager_review|50001|none';
END TRY BEGIN CATCH PRINT CONCAT('trigger|trg_manager_review|50001|',ERROR_NUMBER()); END CATCH;
GO
BEGIN TRY
  INSERT INTO REVIEWS(manager_id,task_id,result_of_review,review_date) VALUES (0,0,'Approved','2000-01-01');
  PRINT 'trigger|trg_review_date|500001|none';
END TRY BEGIN CATCH PRINT CONCAT('trigger|trg_review_date|500001|',ERROR_NUMBER()); END CATCH;
GO
BEGIN TRY
  UPDATE PROJECTS SET project_deadline='2025-01-07' WHERE project_id=0;
  PRINT 'trigger|trg_project_deadline|50004|none';
END TRY BEGIN CATCH PRINT CONCAT('trigger|trg_project_deadline|50004|',ERROR_NUMBER()); END CATCH;
GO
-- The blocked statements must leave no rows behind
SELECT 'after_triggers' section, 'TASKS' name, 308 expected, COUNT(*) actual FROM TASKS
UNION ALL SELECT 'after_triggers', 'TASK_RECORD_BY_ENGINEER', 1263, COUNT(*) FROM TASK_RECORD_BY_ENGINEER
UNION ALL SELECT 'after_triggers', 'REVIEWS', 366, COUNT(*) FROM REVIEWS;
GO

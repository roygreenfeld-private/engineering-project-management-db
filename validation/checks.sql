-- Data checks. Every row is: section|check|expected|actual. A check passes when expected equals actual.
SET NOCOUNT ON;

-- Row counts
SELECT 'row_count' section, 'ROLES' name, 7 expected, COUNT(*) actual FROM ROLES
UNION ALL SELECT 'row_count', 'EMPLOYEES', 30, COUNT(*) FROM EMPLOYEES
UNION ALL SELECT 'row_count', 'PROJECTS', 13, COUNT(*) FROM PROJECTS
UNION ALL SELECT 'row_count', 'EMPLOYEES_IN_PROJECT', 72, COUNT(*) FROM EMPLOYEES_IN_PROJECT
UNION ALL SELECT 'row_count', 'TASKS', 308, COUNT(*) FROM TASKS
UNION ALL SELECT 'row_count', 'TASK_RECORD_BY_ENGINEER', 1263, COUNT(*) FROM TASK_RECORD_BY_ENGINEER
UNION ALL SELECT 'row_count', 'REVIEWS', 366, COUNT(*) FROM REVIEWS;

-- Consistency rules: each count is the number of violations
SELECT 'consistency' section, 'task deadline after project deadline' name, 0 expected, COUNT(*) actual FROM TASKS t JOIN PROJECTS p ON p.project_id=t.project_id WHERE t.task_deadline>p.project_deadline
UNION ALL SELECT 'consistency', 'task deadline before project start', 0, COUNT(*) FROM TASKS t JOIN PROJECTS p ON p.project_id=t.project_id WHERE t.task_deadline<p.project_start_date
UNION ALL SELECT 'consistency', 'record outside project dates', 0, COUNT(*) FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id JOIN PROJECTS p ON p.project_id=t.project_id WHERE r.record_date<p.project_start_date OR r.record_date>p.project_deadline
UNION ALL SELECT 'consistency', 'record after snapshot date', 0, COUNT(*) FROM TASK_RECORD_BY_ENGINEER WHERE record_date>'2026-11-02'
UNION ALL SELECT 'consistency', 'review after snapshot date', 0, COUNT(*) FROM REVIEWS WHERE review_date>'2026-11-02'
UNION ALL SELECT 'consistency', 'record on a weekend', 0, COUNT(*) FROM TASK_RECORD_BY_ENGINEER WHERE DATEDIFF(day,'19000101',record_date)%7 IN (5,6)
UNION ALL SELECT 'consistency', 'Not Started task with records', 0, COUNT(DISTINCT t.task_id) FROM TASKS t JOIN TASK_RECORD_BY_ENGINEER r ON r.task_id=t.task_id WHERE t.task_current_status='Not Started'
UNION ALL SELECT 'consistency', 'In Progress task without records', 0, COUNT(*) FROM TASKS t WHERE t.task_current_status='In Progress' AND NOT EXISTS(SELECT 1 FROM TASK_RECORD_BY_ENGINEER r WHERE r.task_id=t.task_id)
UNION ALL SELECT 'consistency', 'Completed task without records', 0, COUNT(*) FROM TASKS t WHERE t.task_current_status='Completed' AND NOT EXISTS(SELECT 1 FROM TASK_RECORD_BY_ENGINEER r WHERE r.task_id=t.task_id)
UNION ALL SELECT 'consistency', 'record after approval', 0, COUNT(*) FROM TASK_RECORD_BY_ENGINEER r JOIN REVIEWS v ON v.task_id=r.task_id AND v.result_of_review='Approved' WHERE r.record_date>v.review_date
UNION ALL SELECT 'consistency', 'task approved more than once', 0, COUNT(*) FROM (SELECT task_id FROM REVIEWS WHERE result_of_review='Approved' GROUP BY task_id HAVING COUNT(*)>1) x
UNION ALL SELECT 'consistency', 'review after approval', 0, COUNT(*) FROM REVIEWS a JOIN REVIEWS b ON a.task_id=b.task_id AND a.result_of_review='Approved' AND b.review_date>a.review_date
UNION ALL SELECT 'consistency', 'approved task not Completed', 0, COUNT(*) FROM TASKS t JOIN REVIEWS v ON v.task_id=t.task_id AND v.result_of_review='Approved' WHERE t.task_current_status<>'Completed'
UNION ALL SELECT 'consistency', 'task owned by a Manager', 0, COUNT(*) FROM TASKS t JOIN EMPLOYEES e ON e.employee_id=t.employee_id WHERE e.employee_role='Manager'
UNION ALL SELECT 'consistency', 'record author not on project', 0, COUNT(*) FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id LEFT JOIN EMPLOYEES_IN_PROJECT m ON m.project_id=t.project_id AND m.employee_id=r.employee_id WHERE m.employee_id IS NULL
UNION ALL SELECT 'consistency', 'employee day over 11 hours', 0, COUNT(*) FROM (SELECT employee_id,record_date FROM TASK_RECORD_BY_ENGINEER GROUP BY employee_id,record_date HAVING SUM(hours_spent)>11) x
UNION ALL SELECT 'consistency', 'duplicate task name in project', 0, COUNT(*) FROM (SELECT project_id,task_name FROM TASKS GROUP BY project_id,task_name HAVING COUNT(*)>1) x;

-- Edge cases kept in the sample data on purpose, so queries have to handle them
SELECT 'edge_case' section, 'records with NULL result' name, 30 expected, COUNT(*) actual FROM TASK_RECORD_BY_ENGINEER WHERE result_of_record IS NULL
UNION ALL SELECT 'edge_case', 'zero-hour records', 19, COUNT(*) FROM TASK_RECORD_BY_ENGINEER WHERE hours_spent=0
UNION ALL SELECT 'edge_case', 'tasks with NULL deadline', 14, COUNT(*) FROM TASKS WHERE task_deadline IS NULL
UNION ALL SELECT 'edge_case', 'records by non-owner', 61, COUNT(*) FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id WHERE r.employee_id<>t.employee_id
UNION ALL SELECT 'edge_case', 'reviews by manager not on project', 8, COUNT(*) FROM REVIEWS v JOIN TASKS t ON t.task_id=v.task_id LEFT JOIN EMPLOYEES_IN_PROJECT m ON m.project_id=t.project_id AND m.employee_id=v.manager_id WHERE m.employee_id IS NULL
UNION ALL SELECT 'edge_case', 'Completed with no review', 5, COUNT(*) FROM TASKS t WHERE t.task_current_status='Completed' AND NOT EXISTS(SELECT 1 FROM REVIEWS v WHERE v.task_id=t.task_id)
UNION ALL SELECT 'edge_case', 'employees on no project', 4, COUNT(*) FROM EMPLOYEES e WHERE NOT EXISTS(SELECT 1 FROM EMPLOYEES_IN_PROJECT m WHERE m.employee_id=e.employee_id)
UNION ALL SELECT 'edge_case', 'projects with no tasks', 1, COUNT(*) FROM PROJECTS p WHERE NOT EXISTS(SELECT 1 FROM TASKS t WHERE t.project_id=p.project_id)
UNION ALL SELECT 'edge_case', 'employees with NULL role', 1, COUNT(*) FROM EMPLOYEES WHERE employee_role IS NULL;

-- Reference metrics and the patterns built into the sample data
SELECT 'reference' section, 'total hours' name, '5163.5' expected, CONVERT(VARCHAR(20),CAST(SUM(hours_spent) AS DECIMAL(10,1))) actual FROM TASK_RECORD_BY_ENGINEER
UNION ALL SELECT 'reference', 'approved reviews percent', '72.7', CONVERT(VARCHAR(20),CAST(100.0*SUM(CASE WHEN result_of_review='Approved' THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,1))) FROM REVIEWS
UNION ALL SELECT 'reference', 'Noa Shapira task count', '40', CONVERT(VARCHAR(20),COUNT(*)) FROM TASKS t JOIN EMPLOYEES e ON e.employee_id=t.employee_id WHERE e.employee_name='Noa Shapira'
UNION ALL SELECT 'reference', 'Idan Rosen rejected percent', '59.4', CONVERT(VARCHAR(20),CAST(100.0*SUM(CASE WHEN v.result_of_review='Rejected' THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,1))) FROM REVIEWS v JOIN TASKS t ON t.task_id=v.task_id JOIN EMPLOYEES e ON e.employee_id=t.employee_id WHERE e.employee_name='Idan Rosen'
UNION ALL SELECT 'reference', 'Logistics Platform on-time percent', '32.1', CONVERT(VARCHAR(20),CAST(100.0*SUM(CASE WHEN v.review_date<=t.task_deadline THEN 1 ELSE 0 END)/COUNT(*) AS DECIMAL(5,1))) FROM REVIEWS v JOIN TASKS t ON t.task_id=v.task_id JOIN PROJECTS p ON p.project_id=t.project_id WHERE v.result_of_review='Approved' AND t.task_deadline IS NOT NULL AND p.project_name='Logistics Platform'
UNION ALL SELECT 'reference', 'priority 1 average hours per record', '5.41', CONVERT(VARCHAR(20),CAST(AVG(r.hours_spent) AS DECIMAL(5,2))) FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id WHERE t.task_priority=1
UNION ALL SELECT 'reference', 'priority 5 average hours per record', '2.56', CONVERT(VARCHAR(20),CAST(AVG(r.hours_spent) AS DECIMAL(5,2))) FROM TASK_RECORD_BY_ENGINEER r JOIN TASKS t ON t.task_id=r.task_id WHERE t.task_priority=5;

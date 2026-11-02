/*
SELECT r.role_name,
COUNT(e.employee_role) AS Total_At_This_Role
FROM ROLES r LEFT JOIN EMPLOYEES e ON r.role_name=e.employee_role
GROUP BY r.role_name
*/
/*
SELECT p.project_id,p.project_name,
ISNULL(SUM(tr.hours_spent),0) AS Total_Hours_Spent,
COUNT(DISTINCT t.task_id) AS Total_Diffrent_Task_Per_Project
FROM TASK_RECORD_BY_ENGINEER tr JOIN TASKS t ON tr.task_id=t.task_id
RIGHT JOIN PROJECTS p ON t.project_id=p.project_id
GROUP BY p.project_id, p.project_name
*/
/*
WITH CTE AS (
    SELECT p.project_id,p.project_name,
    COUNT(t.task_current_status) AS Total_Completed_Tasks
    FROM PROJECTS p LEFT JOIN TASKS t ON p.project_id=t.project_id AND t.task_current_status='Completed'
    GROUP BY p.project_id,p.project_name
)
*/
/*
SELECT c.project_id,c.project_name,
CONCAT(c.Total_Completed_Tasks*100.0/NULLIF(COUNT(t.task_id),0),'%') AS precents_finised
FROM CTE c LEFT JOIN TASKS t ON c.project_id=t.project_id 
GROUP BY c.project_id,c.project_name,c.Total_Completed_Tasks
*/

/*
SELECT t.task_id,t.task_name,t.task_current_status,t.task_deadline,t.task_priority,
(DATEDIFF(day, t.task_deadline,'2026-11-02')) AS Latnes
FROM TASKS t
WHERE t.task_deadline<'2026-11-02' AND t.task_current_status!='Completed'
GROUP BY t.task_id,t.task_name,t.task_current_status,t.task_deadline,t.task_priority
ORDER BY t.task_priority,Latnes DESC
*/


/*
WITH FirstReview AS ( --order each task's reviews by date
    SELECT
        task_id,
        result_of_review,
        ROW_NUMBER() OVER (
            PARTITION BY task_id
            ORDER BY review_date ASC, review_id ASC
        ) AS rn
    FROM REVIEWS
)
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(*) AS reviewed_tasks,
    SUM(CASE
            WHEN fr.result_of_review = 'Approved'
            THEN 1 ELSE 0
        END) AS first_review_approved,

    100.0 * SUM(CASE
                    WHEN fr.result_of_review = 'Approved'
                    THEN 1 ELSE 0
                END) / COUNT(*) AS approval_rate

FROM EMPLOYEES e
JOIN TASKS t
    ON e.employee_id = t.employee_id
JOIN FirstReview fr
    ON t.task_id = fr.task_id
   AND fr.rn = 1

GROUP BY
    e.employee_id,
    e.employee_name

HAVING COUNT(*) >= 5;
*/
/*
--סיכום שעות עבודה לכל עובד בכל פרויקט
WITH total_per_project AS (
SELECT tr.employee_id,t.project_id,SUM(tr.hours_spent) AS total_hours_spent_on_project
FROM TASK_RECORD_BY_ENGINEER tr JOIN TASKS t ON tr.task_id=t.task_id
GROUP BY tr.employee_id,t.project_id
),
--סך השעות הכולל בפרויקט
sum_project AS(
SELECT *,SUM(tp.total_hours_spent_on_project) OVER(PARTITION BY tp.project_id) AS total_hours_of_project
FROM total_per_project tp
),
--דירוג העובדים לפי פרויקט
rank_employees AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY sp.project_id
                                 ORDER BY sp.total_hours_spent_on_project DESC) AS rank
    FROM sum_project sp
)

SELECT rp.project_id,rp.employee_id,e.employee_name,rp.total_hours_spent_on_project,rp.rank,(100.0*rp.total_hours_spent_on_project/rp.total_hours_of_project) AS part_from_project_in_precentece
FROM rank_employees rp JOIN EMPLOYEES e ON rp.employee_id=e.employee_id
WHERE rp.rank<=3 AND rp.rank>=1
ORDER BY rp.project_id,rp.rank

*/

/*
WITH hours_per_month AS(
    SELECT e.employee_id,employee_name,SUM(tr.hours_spent) AS hours_per_month,MONTH(tr.record_date) AS month,YEAR(tr.record_date) AS year
    FROM EMPLOYEES e JOIN TASK_RECORD_BY_ENGINEER tr ON e.employee_id=tr.employee_id
    GROUP BY e.employee_id,e.employee_name,MONTH(tr.record_date),YEAR(tr.record_date)
),
gap_from_last_month AS(
    SELECT *,hp.hours_per_month-LAG(hp.hours_per_month) OVER(PARTITION BY hp.employee_id
                                                         ORDER BY hp.year,hp.month) AS Gap_From_Last_Month
    FROM hours_per_month hp
)
SELECT e.employee_id,e.employee_name,gm.month,gm.year,gm.hours_per_month,gm.Gap_From_Last_Month,SUM(gm.hours_per_month) OVER(PARTITION BY e.employee_id
                                                                                                                            ORDER BY gm.year,gm.month) AS Counting_Sum
FROM gap_from_last_month gm RIGHT JOIN EMPLOYEES e ON gm.employee_id=e.employee_id
ORDER BY e.employee_id
*/






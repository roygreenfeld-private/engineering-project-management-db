CREATE TABLE PROJECTS (
    project_id INT IDENTITY(0,1) PRIMARY KEY ,
    project_name VARCHAR(20) NOT NULL,
    project_start_date DATE NOT NULL,
    project_deadline DATE,

    CONSTRAINT CK_project_dates
      CHECK(project_deadline>=project_start_date)
);
GO

CREATE TABLE ROLES (
    role_name VARCHAR(50) PRIMARY KEY
);
GO

CREATE TABLE EMPLOYEES (
    employee_id INT IDENTITY(0,1) PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    employee_role VARCHAR(50) REFERENCES ROLES(role_name)
);
GO

CREATE TABLE EMPLOYEES_IN_PROJECT (
    project_id INT REFERENCES PROJECTS(project_id),
    employee_id INT REFERENCES EMPLOYEES(employee_id),
    role_name VARCHAR(50) REFERENCES ROLES(role_name),

    PRIMARY KEY(project_id,employee_id)
);
GO

CREATE TABLE TASKS(
    task_id INT IDENTITY(0,1) PRIMARY KEY ,
    employee_id INT NOT NULL,
    project_id INT NOT NULL,
    task_name VARCHAR(50) NOT NULL,
    task_priority INT NOT NULL CHECK (task_priority>0),
    task_current_status VARCHAR(20) NOT NULL 
    CHECK (task_current_status IN ('Completed','In Progress','Not Started')),
    task_deadline DATE, --will create trigger for making sure that task_deadline<=project_deadline

    CONSTRAINT FK_taks_project_employee
    FOREIGN KEY(project_id,employee_id)
    REFERENCES EMPLOYEES_IN_PROJECT(project_id,employee_id)
);
GO

CREATE TRIGGER trg_task_deadline ON TASKS --creating new trigger name on tasks table
AFTER INSERT,UPDATE   --starting when insert/update
AS
BEGIN
 IF EXISTS( --checks if there is even 1 row that not valid
    SELECT 1 
    FROM inserted i --logic table automticly suporrted by sql server
    JOIN PROJECTS p
    ON p.project_id=i.project_id
    WHERE i.task_deadline>p.project_deadline --buissnes check
 )
 BEGIN 
  ;THROW 50001, 'Task deadline exceeds project deadline',1; --creating error and printing  
  END --close if
END;
GO --close trigger

CREATE TABLE TASK_RECORD_BY_ENGINEER (
    record_num INT IDENTITY(0,1) PRIMARY KEY,
    task_id INT REFERENCES TASKS(task_id) NOT NULL,
    employee_id INT REFERENCES EMPLOYEES(employee_id) NOT NULL,
    hours_spent DECIMAL(20,2) NOT NULL CHECK (hours_spent>=0),
    record_date DATE NOT NULL,
    result_of_record INT CHECK (result_of_record>=0)
);
GO

CREATE TRIGGER trg_record_date ON TASK_RECORD_BY_ENGINEER
AFTER UPDATE,INSERT
AS
BEGIN
 IF EXISTS(
 SELECT 1
 FROM inserted i
        JOIN TASKS t
            ON i.task_id = t.task_id
        JOIN PROJECTS p
            ON t.project_id = p.project_id
            WHERE i.record_date > p.project_deadline
         OR i.record_date < p.project_start_date
 )
 BEGIN 
  ;THROW 500001 ,'Logic Error, record date not in range',2;
 END
END;
GO


CREATE TABLE REVIEWS(
review_id INT IDENTITY(0,1) PRIMARY KEY,
manager_id INT REFERENCES EMPLOYEES(employee_id) NOT NULL,
task_id INT REFERENCES TASKS(task_id) NOT NULL,
result_of_review VARCHAR(20) CHECK(result_of_review IN ('Approved','Rejected')) NOT NULL,
review_date DATE NOT NULL
);
GO

CREATE TRIGGER trg_manager_review ON REVIEWS
AFTER INSERT,UPDATE
AS
BEGIN
 IF EXISTS(
  SELECT 1
  FROM inserted i
        JOIN EMPLOYEES e
            ON i.manager_id = e.employee_id
        WHERE e.employee_role <> 'Manager'
           OR e.employee_role IS NULL
 )
 BEGIN 
  ;THROW 50001, 'Only Manger can record task',3;
 END
END;
GO


CREATE TRIGGER trg_review_date ON REVIEWS
AFTER INSERT,UPDATE
AS
BEGIN
     IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM TASK_RECORD_BY_ENGINEER r
            WHERE r.task_id = i.task_id
              AND r.record_date <= i.review_date
 )
     )
  BEGIN
  ;THROW 500001, 'engineer must check and record before manger review',4;
  END
END;
GO

CREATE TRIGGER trg_project_deadline
ON PROJECTS
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN TASKS t
            ON i.project_id = t.project_id
        WHERE t.task_deadline > i.project_deadline
    )
    BEGIN
        ;THROW 50004,
              'Project deadline is earlier than task deadline',
              1;
    END
END;
GO

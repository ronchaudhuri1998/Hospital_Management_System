set search_path to hospital


/* DROP statements */

-- Drop Triggers
DROP TRIGGER IF EXISTS TRG_Department ON Department;
DROP TRIGGER IF EXISTS TRG_Doctor ON Doctor;
DROP TRIGGER IF EXISTS TRG_Patient ON Patient;
DROP TRIGGER IF EXISTS TRG_Appointment ON Appointment;
DROP TRIGGER IF EXISTS TRG_Bill ON Bill;

-- Drop Trigger Functions
DROP FUNCTION IF EXISTS dept_trigger_function()  CASCADE;
DROP FUNCTION IF EXISTS doctor_trigger_function()  CASCADE;
DROP FUNCTION IF EXISTS patient_trigger_function()  CASCADE;
DROP FUNCTION IF EXISTS set_default_appointment_values ()  CASCADE;
DROP FUNCTION IF EXISTS bill_trigger_function()  CASCADE;

-- Drop Sequences
DROP SEQUENCE IF EXISTS SEQ_Department_Dept_ID;
DROP SEQUENCE IF EXISTS SEQ_Doctor_Doctor_ID;
DROP SEQUENCE IF EXISTS SEQ_Patient_Patient_ID;
DROP SEQUENCE IF EXISTS SEQ_Appointment_App_ID;
DROP SEQUENCE IF EXISTS SEQ_Bill_Bill_ID;

-- Drop Altered Table Columns and Constraints
ALTER TABLE Department DROP COLUMN IF EXISTS Dept_Head;
ALTER TABLE Department DROP CONSTRAINT IF EXISTS valid_dept_phone;

ALTER TABLE Doctor DROP CONSTRAINT IF EXISTS unique_doctor_num;
ALTER TABLE Doctor DROP COLUMN IF EXISTS Doctor_Email;
ALTER TABLE Doctor DROP CONSTRAINT IF EXISTS doctor_dept_id_fkey;

ALTER TABLE Patient DROP COLUMN IF EXISTS Patient_Phone;
ALTER TABLE Patient DROP CONSTRAINT IF EXISTS patient_doctor_id_fkey;

ALTER TABLE Appointment DROP CONSTRAINT IF EXISTS valid_status;
ALTER TABLE Appointment DROP CONSTRAINT IF EXISTS valid_payment;
ALTER TABLE Appointment DROP CONSTRAINT IF EXISTS appointment_doctor_id_fkey;
ALTER TABLE Appointment DROP CONSTRAINT IF EXISTS appointment_patient_id_fkey;

ALTER TABLE Bill DROP COLUMN IF EXISTS Pay_Due_Date;
ALTER TABLE Bill DROP CONSTRAINT IF EXISTS bill_app_id_fkey;

-- Drop Views
DROP VIEW IF EXISTS view_patient_doctors;
DROP VIEW IF EXISTS view_patient_history;
DROP VIEW IF EXISTS view_upcoming_appointments;
DROP VIEW IF EXISTS view_unpaid_bills;

-- Drop Tables
DROP TABLE IF EXISTS Department CASCADE;
DROP TABLE IF EXISTS Doctor CASCADE;
DROP TABLE IF EXISTS Patient CASCADE;
DROP TABLE IF EXISTS Appointment CASCADE;
DROP TABLE IF EXISTS Bill CASCADE;


/* CREATE statements */

-- Create Department table
CREATE TABLE Department (
    Dept_ID INT PRIMARY KEY,
    Dept_Name VARCHAR(100),
    Dept_Location VARCHAR(100),
    Services VARCHAR(255),
    Dept_Phone VARCHAR(15)
);

-- Create Doctor table
CREATE TABLE Doctor (
    Doctor_ID INT PRIMARY KEY,
    Doctor_Fname VARCHAR(100),
    Doctor_Lname VARCHAR(100),
    Specialty VARCHAR(100),
    Doctor_Num VARCHAR(15),
    Start_Date DATE,
    Dept_ID INT,
    FOREIGN KEY (Dept_ID) REFERENCES Department(Dept_ID)
);

-- Create Patient table
CREATE TABLE Patient (
    Patient_ID INT PRIMARY KEY,
    Patient_Fname VARCHAR(100),
    Patient_Lname VARCHAR(100),
    DOB DATE,
    Address VARCHAR(255),
    ER_Number VARCHAR(15),
    Doctor_ID INT,
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Doctor_ID)
);

-- Create Appointment table
CREATE TABLE Appointment (
    App_ID INT PRIMARY KEY,
    App_Date DATE,
    App_Time TIME,
    Visit_Reason VARCHAR(255),
    Status VARCHAR(50),
    Payment VARCHAR(50),
    Patient_ID INT,
    Doctor_ID INT,
    FOREIGN KEY (Patient_ID) REFERENCES Patient(Patient_ID),
    FOREIGN KEY (Doctor_ID) REFERENCES Doctor(Doctor_ID)
);

-- Create Bill table
CREATE TABLE Bill (
    Bill_ID INT PRIMARY KEY,
    Bill_Amt DECIMAL(10, 2),
    Tax DECIMAL(10, 2),
    Discount DECIMAL(10, 2),
    Pay_Status VARCHAR(50),
    Pay_Method VARCHAR(50),
    App_ID INT,
    FOREIGN KEY (App_ID) REFERENCES Appointment(App_ID)
);

/* Alter Tables to add constraints and columns */

-- Department table constraints
ALTER TABLE Department
ADD COLUMN Dept_Head VARCHAR(100);
ALTER TABLE Department
ADD CONSTRAINT valid_dept_phone CHECK (LENGTH(Dept_Phone) <= 15);

-- Doctor table constraints
ALTER TABLE Doctor
ADD CONSTRAINT unique_doctor_num UNIQUE (Doctor_Num);
ALTER TABLE Doctor
ADD COLUMN Doctor_Email VARCHAR(100);

-- Patient table constraints
ALTER TABLE Patient
ADD COLUMN Patient_Phone VARCHAR(15);

-- Appointment table constraints
ALTER TABLE Appointment
ADD CONSTRAINT valid_status CHECK (Status IN ('Scheduled', 'Completed', 'Cancelled'));
ALTER TABLE Appointment
ADD CONSTRAINT valid_payment CHECK (Payment IN ('Paid', 'Pending', 'Unpaid'));

-- Bill table constraints
ALTER TABLE Bill
ADD COLUMN Pay_Due_Date DATE;

/* CREATE Views */

-- View to show patients and their assigned doctors
CREATE VIEW view_patient_doctors AS
SELECT 
    Patient_ID,
    Patient_Fname || ' ' || Patient_Lname AS Patient_Name,
    Doctor_ID,
    ER_Number
FROM Patient;

-- View to list upcoming appointments
CREATE VIEW view_upcoming_appointments AS
SELECT 
    App_ID,
    App_Date,
    App_Time,
    Visit_Reason,
    Patient_ID,
    Doctor_ID,
    Status
FROM Appointment
WHERE Status = 'Scheduled';

-- View to show unpaid bills
CREATE VIEW view_unpaid_bills AS
SELECT 
    Bill_ID,
    Bill_Amt,
    Tax,
    Discount,
    Pay_Status,
    App_ID
FROM Bill
WHERE Pay_Status = 'Pending';

-- View to show patient history of completed appointments
CREATE VIEW view_patient_history AS
SELECT 
    Patient_ID,
    App_ID,
    App_Date,
    Visit_Reason,
    Status
FROM Appointment
WHERE Status = 'Completed';

/* CREATE Sequences */

-- Sequence for Department
CREATE SEQUENCE SEQ_Department_Dept_ID
START WITH 101 INCREMENT BY 1;

-- Sequence for Appointment
CREATE SEQUENCE SEQ_Appointment_App_ID
START WITH 11 INCREMENT BY 1;

-- Sequence for Doctor
CREATE SEQUENCE SEQ_Doctor_Doctor_ID
START WITH 1 INCREMENT BY 1;

-- Sequence for Patient
CREATE SEQUENCE SEQ_Patient_Patient_ID
START WITH 1001 INCREMENT BY 1;

-- Sequence for Bill
CREATE SEQUENCE SEQ_Bill_Bill_ID
START WITH 11 INCREMENT BY 1;

/* CREATE Triggers */

-- Trigger for Department
CREATE OR REPLACE FUNCTION dept_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.Dept_ID IS NULL THEN
    NEW.Dept_ID = NEXTVAL('SEQ_Department_Dept_ID');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Department
BEFORE INSERT ON Department
FOR EACH ROW
EXECUTE FUNCTION dept_trigger_function();

-- Trigger for Appointment
CREATE OR REPLACE FUNCTION set_default_appointment_values()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.App_ID IS NULL THEN
    NEW.App_ID = NEXTVAL('SEQ_Appointment_App_ID');
  END IF;

  IF NEW.App_Date IS NULL THEN
    NEW.App_Date = CURRENT_DATE + INTERVAL '7 days';
  END IF;

  IF NEW.App_Time IS NULL THEN
    NEW.App_Time = '14:00';
  END IF;

  IF NEW.Payment IS NULL THEN
    NEW.Payment = 'Paid';
  END IF;

  IF NEW.Status IS NULL THEN
    NEW.Status = 'Scheduled';
  END IF;

  IF NEW.Visit_Reason IS NULL THEN
    NEW.Visit_Reason = 'Consultation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Appointment
BEFORE INSERT ON Appointment
FOR EACH ROW
EXECUTE FUNCTION set_default_appointment_values();

-- Trigger for Doctor
CREATE OR REPLACE FUNCTION doctor_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.Doctor_ID IS NULL THEN
    NEW.Doctor_ID = NEXTVAL('SEQ_Doctor_Doctor_ID');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Doctor
BEFORE INSERT ON Doctor
FOR EACH ROW
EXECUTE FUNCTION doctor_trigger_function();

-- Trigger for Patient
CREATE OR REPLACE FUNCTION patient_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.Patient_ID IS NULL THEN
    NEW.Patient_ID = NEXTVAL('SEQ_Patient_Patient_ID');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Patient
BEFORE INSERT ON Patient
FOR EACH ROW
EXECUTE FUNCTION patient_trigger_function();

-- Trigger for Bill
CREATE OR REPLACE FUNCTION bill_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.Bill_ID IS NULL THEN
    NEW.Bill_ID = NEXTVAL('SEQ_Bill_Bill_ID');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Bill
BEFORE INSERT ON Bill
FOR EACH ROW
EXECUTE FUNCTION bill_trigger_function();

--Inserting data into the tables

INSERT INTO Department (Dept_ID, Dept_Name, Dept_Location, Services, Dept_Phone, Dept_Head)
VALUES 
(NEXTVAL('SEQ_Department_Dept_ID'), 'Cardiology', 'Building A', 'Heart health', '1234567890', 'Dr. Alice Johnson'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Neurology', 'Building B', 'Brain health', '2345678901', 'Dr. Bob Smith'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Orthopedics', 'Building C', 'Bone health', '3456789012', 'Dr. Carol Davis'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Pediatrics', 'Building D', 'Child health', '4567890123', 'Dr. Daniel Thompson'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Dermatology', 'Building E', 'Skin health', '5678901234', 'Dr. Evelyn Clarke'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Oncology', 'Building F', 'Cancer treatment', '6789012345', 'Dr. Frank Harris'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Gastroenterology', 'Building G', 'Digestive health', '7890123456', 'Dr. Grace Adams'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Psychiatry', 'Building H', 'Mental health', '8901234567', 'Dr. Hank Brown'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Radiology', 'Building I', 'Imaging services', '9012345678', 'Dr. Ian White'),
(NEXTVAL('SEQ_Department_Dept_ID'), 'Ophthalmology', 'Building J', 'Eye health', '0123456789', 'Dr. Jill Wilson');

INSERT INTO Doctor (Doctor_ID, Doctor_Fname, Doctor_Lname, Specialty, Doctor_Num, Start_Date, Dept_ID, Doctor_Email)
VALUES 
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Alice', 'Johnson', 'Cardiology', 'D001', '2020-01-15', 101, 'alice.johnson@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Bob', 'Smith', 'Neurology', 'D002', '2019-06-01', 102, 'bob.smith@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Carol', 'Davis', 'Orthopedics', 'D003', '2018-09-21', 103, 'carol.davis@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Daniel', 'Thompson', 'Pediatrics', 'D004', '2021-03-12', 104, 'daniel.thompson@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Evelyn', 'Clarke', 'Dermatology', 'D005', '2017-12-01', 105, 'evelyn.clarke@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Frank', 'Harris', 'Oncology', 'D006', '2022-01-25', 106, 'frank.harris@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Grace', 'Adams', 'Gastroenterology', 'D007', '2020-07-15', 107, 'grace.adams@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Hank', 'Brown', 'Psychiatry', 'D008', '2021-08-05', 108, 'hank.brown@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Ian', 'White', 'Radiology', 'D009', '2019-04-17', 109, 'ian.white@hospital.com'),
(NEXTVAL('SEQ_Doctor_Doctor_ID'), 'Jill', 'Wilson', 'Ophthalmology', 'D010', '2022-09-10', 110, 'jill.wilson@hospital.com');

INSERT INTO Patient (Patient_ID, Patient_Fname, Patient_Lname, DOB, Address, ER_Number, Doctor_ID, Patient_Phone)
VALUES 
(NEXTVAL('SEQ_Patient_Patient_ID'), 'John', 'Doe', '1985-05-12', '123 Main St', 'ER1001', 1, '3216549870'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Jane', 'Smith', '1990-08-25', '456 Oak St', 'ER1002', 10, '9876543210'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Sam', 'Johnson', '1975-12-11', '789 Pine St', 'ER1003', 3, '6549873210'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Mary', 'Brown', '1968-03-04', '101 Maple St', 'ER1004', 4, '9638527410'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Mike', 'Davis', '2002-11-19', '202 Cedar St', 'ER1005', 5, '7418529630'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Sue', 'Adams', '1995-09-30', '303 Birch St', 'ER1006', 6, '2589631470'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Tom', 'White', '1988-02-22', '404 Elm St', 'ER1007', 7, '8529637410'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Sara', 'Wilson', '1997-07-14', '505 Walnut St', 'ER1008', 8, '1597534860'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Paul', 'Thomas', '1981-01-01', '606 Willow St', 'ER1009', 9, '1234567890'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Anna', 'Lee', '1993-06-15', '707 Spruce St', 'ER1010', 10, '7896541230'),
(NEXTVAL('SEQ_Patient_Patient_ID'), 'Rock', 'Lee', '1993-11-15', '709 Hunt St', 'ER1010', 10, '78965412355');

INSERT INTO Appointment (App_ID, App_Date, App_Time, Visit_Reason, Status, Payment, Patient_ID, Doctor_ID)
VALUES 
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-01', '09:00', 'Routine Checkup', 'Scheduled', 'Pending', 1001, 1),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-03', '10:30', 'Headache', 'Scheduled', 'Paid', 1002, 10),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-05', '14:00', 'Back Pain', 'Scheduled', 'Unpaid', 1003, 3),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-08', '16:00', 'Vaccination', 'Scheduled', 'Paid', 1004, 4),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-10', '12:00', 'Skin Rash', 'Scheduled', 'Pending', 1005, 5),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-12', '11:00', 'Cancer Follow-up', 'Scheduled', 'Paid', 1006, 6),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-15', '15:00', 'Stomach Pain', 'Scheduled', 'Unpaid', 1007, 7),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-18', '13:00', 'Anxiety Consultation', 'Scheduled', 'Paid', 1008, 8),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-20', '08:30', 'X-Ray', 'Scheduled', 'Pending', 1009, 9),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-22', '14:00', 'Vision Check', 'Scheduled', 'Paid', 1010, 10),
(NEXTVAL('SEQ_Appointment_App_ID'), '2024-12-22', '15:00', 'Vision Check', 'Scheduled', 'Paid', 1011, 10);

INSERT INTO Bill (Bill_ID, Bill_Amt, Tax, Discount, Pay_Status, Pay_Method, App_ID, Pay_Due_Date)
VALUES 
(NEXTVAL('SEQ_Bill_Bill_ID'), 200.00, 10.00, 0.00, 'Paid', 'Credit Card', 11, NULL),
(NEXTVAL('SEQ_Bill_Bill_ID'), 150.00, 7.50, 5.00, 'Pending', 'Cash', 12, '2024-12-05'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 300.00, 15.00, 10.00, 'Unpaid', 'Insurance', 13, '2024-12-08'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 100.00, 5.00, 0.00, 'Paid', 'Credit Card', 14, NULL),
(NEXTVAL('SEQ_Bill_Bill_ID'), 250.00, 12.50, 0.00, 'Pending', 'Cash', 15, '2024-12-12'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 400.00, 20.00, 50.00, 'Paid', 'Credit Card', 16, NULL),
(NEXTVAL('SEQ_Bill_Bill_ID'), 500.00, 25.00, 0.00, 'Unpaid', 'Insurance', 17, '2024-12-18'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 350.00, 17.50, 15.00, 'Pending', 'Cash', 18, '2024-12-22'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 100.00, 5.00, 0.00, 'Paid', 'Credit Card', 19, NULL),
(NEXTVAL('SEQ_Bill_Bill_ID'), 200.00, 10.00, 0.00, 'Pending', 'Cash', 20, '2024-12-31'),
(NEXTVAL('SEQ_Bill_Bill_ID'), 200.00, 10.00, 0.00, 'Pending', 'Cash', 21, '2024-12-31');




-- Select * from doctor
-- Select * from appointment
-- Select * from bill
-- Select * from patient
-- Select * from department

-- select * from view_patient_doctors


-- 1. Select all columns and all rows from one table 

SELECT * 
FROM patient;
 
-- 2. Select five columns and all rows from one table 

SELECT doctor_id, doctor_fname, doctor_lname, specialty, doctor_num
FROM doctor;
 
-- 3. Select all columns from all rows from one view 

SELECT * 
FROM view_unpaid_bills;
 
-- 4. Using a join on 2 tables, select all columns and all rows from the tables 
--    without the use of a Cartesian product 

SELECT *
FROM patient JOIN doctor ON patient.doctor_id=doctor.doctor_id;
 
-- 5. Select and order data retrieved from one table 

SELECT * 
FROM appointment 
ORDER BY app_date;
 
-- 6. Using a join on 3 tables, select 5 columns from the 3 tables. 

--    Use syntax that would limit the output to 3 rows 

SELECT p.patient_id, d.doctor_id, a.app_id,a.app_date, a.app_time
FROM patient p INNER JOIN doctor d ON p.doctor_id=d.doctor_id
INNER JOIN appointment a ON a.patient_id=p.patient_id AND a.doctor_id=d.doctor_id
LIMIT 3;
 
 
-- 7. Select distinct rows using joins on 3 tables  

SELECT distinct p.patient_id, d.doctor_id, a.app_id,a.app_date, a.app_time
FROM patient p INNER JOIN doctor d ON p.doctor_id=d.doctor_id
INNER JOIN appointment a ON a.patient_id=p.patient_id AND a.doctor_id=d.doctor_id;
 
 
-- 8. Use GROUP BY and HAVING in a select statement using one or more tables 

SELECT d.doctor_id, COUNT(patient_id) AS "Number of Patient"
FROM patient p INNER JOIN doctor d ON p.doctor_id=d.doctor_id
GROUP BY d.doctor_id
HAVING count(patient_id)>=3;
 


-- 9. Use IN clause to select data from one or more tables 

SELECT p.patient_id, p.patient_Fname, p.patient_Lname, d.Doctor_Fname, d.Doctor_Lname
FROM patient p INNER JOIN doctor d ON p.doctor_id=d.doctor_id
WHERE p.doctor_id IN (6,10);
 
 
-- 10. Select length of one column from one table (use LENGTH function) 

SELECT patient_fname, LENGTH(patient_fname) AS Length_Patient_Fname
FROM patient;
 
 
-- 11. Delete one record from one table. 

--     Use select statements to demonstrate the table contents before and after the DELETE statement. 

--     Make sure you use ROLLBACK afterwards so that the data will not be physically removed 

BEGIN;
SELECT * FROM bill;
DELETE FROM bill WHERE bill_id=20;
SELECT * FROM bill;
ROLLBACK;
SELECT * FROM bill;
 
 
-- 12. Update one record from one table. 

--	   Use select statements to demonstrate the table contents before and after the UPDATE statement. 

--     Make sure you use ROLLBACK afterwards so that the data will not be physically removed 

BEGIN;
SELECT * FROM doctor;
UPDATE doctor SET Specialty='Neurology' WHERE doctor_id=1;
SELECT * FROM doctor;
ROLLBACK;
SELECT * FROM doctor;
 
-- 13. complex query (Appointment details of a doctor who has more than 2 appointments)

SELECT 
    d.Doctor_ID,
    d.Doctor_Fname || ' ' || d.Doctor_Lname AS Doctor_Name,
    a.App_ID,
    a.App_Date,
    a.App_Time,
    a.Visit_Reason,
    a.Status,
    a.Payment,
    a.Patient_ID
FROM 
    Doctor d
JOIN 
    Appointment a ON d.Doctor_ID = a.Doctor_ID
WHERE 
    d.Doctor_ID IN (
        SELECT Doctor_ID
        FROM Appointment
        GROUP BY Doctor_ID
        HAVING COUNT(App_ID) > 2
    )
ORDER BY 
    d.Doctor_ID, a.App_Date;
 
 
-- 14. complex query (Revenue generated from each Payment Method in the hospital)

SELECT pay_method AS "Payment Method", AVG(bill_amt) AS "Average Bill Amount", MAX(bill_amt) AS "Maximum Bill Amount", MIN(bill_amt) AS "Minimum Bill Amount",
sum(bill_amt) AS "Revenue Generated"
FROM bill
GROUP BY pay_method
ORDER BY SUM(bill_amt) DESC;
 

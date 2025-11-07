# 🏥 Hospital Management Database System

A relational database for managing hospital operations — including patients, doctors, departments, appointments, and billing — built with **PostgreSQL** as part of **BUAN 6320: Database Foundations for Business Analytics (UT Dallas)**.

## 📘 Overview

The Hospital Management System (HMS) database is designed to:

- Store, query, and maintain core hospital data.
- Enforce data integrity through primary/foreign keys and constraints.
- Automate common tasks using sequences and triggers.
- Provide ready-made SQL views for billing, scheduling, and patient tracking.

## 🧱 Schema Design

### Core Entities

- `Patient`
- `Doctor`
- `Department`
- `Appointment`
- `Bill`

### Relationships

- **Patient → Doctor**: many-to-one  
- **Doctor → Department**: many-to-one  
- **Patient → Appointment**: one-to-many  
- **Doctor → Appointment**: one-to-many  
- **Appointment → Bill**: one-to-one  
- **Patient → Bill**: one-to-one per appointment

## 🧩 Table Summaries

### Patient

| Column | Description |
| :----- | :---------- |
| `Patient_ID` | Primary key |
| `Patient_Fname`, `Patient_Lname` | Patient’s name |
| `DOB`, `Address`, `ER_Number`, `Patient_Phone` | Personal information |
| `Doctor_ID` | Foreign key → `Doctor.Doctor_ID` |

### Doctor

| Column | Description |
| :----- | :---------- |
| `Doctor_ID` | Primary key |
| `Doctor_Fname`, `Doctor_Lname` | Name |
| `Specialty`, `Doctor_Num` | Specialty & unique doctor code |
| `Start_Date`, `Doctor_Email` | Employment & contact info |
| `Dept_ID` | Foreign key → `Department.Dept_ID` |

### Department

| Column | Description |
| :----- | :---------- |
| `Dept_ID` | Primary key |
| `Dept_Name` | Department name |
| `Dept_Location` | Location in hospital |
| `Services` | Services provided |
| `Dept_Phone` | Contact number |
| `Dept_Head` | Head of department |

### Appointment

| Column | Description |
| :----- | :---------- |
| `App_ID` | Primary key |
| `App_Date`, `App_Time` | Date and time of appointment |
| `Visit_Reason` | Reason for visit |
| `Status` | `Scheduled`, `Completed`, or `Cancelled` |
| `Payment` | `Paid`, `Pending`, or `Unpaid` |
| `Patient_ID` | Foreign key → `Patient.Patient_ID` |
| `Doctor_ID` | Foreign key → `Doctor.Doctor_ID` |

### Bill

| Column | Description |
| :----- | :---------- |
| `Bill_ID` | Primary key |
| `Bill_Amt`, `Tax`, `Discount` | Billing amounts |
| `Pay_Status` | Payment status |
| `Pay_Method` | Cash, card, insurance, etc. |
| `Pay_Due_Date` | Due date if not paid |
| `App_ID` | Foreign key → `Appointment.App_ID` |

## ⚙️ Implementation Details

- **DBMS**: PostgreSQL (managed via pgAdmin 4)  
- **Normalization**: All tables designed to **Third Normal Form (3NF)**.  
- **Sequences**: One sequence per table (e.g., `SEQ_Patient_Patient_ID`).  
- **Triggers**:
  - Auto-generate IDs from sequences on insert.
  - Set default values for new appointments (date, time, status, payment, visit reason).

## 👀 Views

- `view_patient_doctors` – patients and their assigned doctors.  
- `view_upcoming_appointments` – all scheduled appointments.  
- `view_unpaid_bills` – bills with pending payment.  
- `view_patient_history` – completed appointments per patient.

## 🧠 Example Queries

### Doctors with more than two appointments

```sql
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
FROM Doctor d
JOIN Appointment a 
  ON d.Doctor_ID = a.Doctor_ID
WHERE d.Doctor_ID IN (
  SELECT Doctor_ID
  FROM Appointment
  GROUP BY Doctor_ID
  HAVING COUNT(App_ID) > 2
)
ORDER BY d.Doctor_ID, a.App_Date;
```

### Payment method generating the highest revenue

```sql
SELECT 
  Pay_Method,
  SUM(Bill_Amt + Tax - Discount) AS Total_Revenue
FROM Bill
GROUP BY Pay_Method
ORDER BY Total_Revenue DESC
LIMIT 1;
```

## 🧰 Tech Stack

- **Database**: PostgreSQL  
- **Admin Tool**: pgAdmin 4  
- **Diagramming**: ER-Assistant (Crow’s Foot notation)  

## 🚀 How to Run

1. Clone the repository:

   ```bash
   git clone <repo-url>
   cd hospital-management-database
   ```

2. In `pgAdmin`, run the DDL script to create tables, sequences, views, and triggers.

3. Run the DML script to insert sample data.

4. Test views and queries, for example:

   ```sql
   SELECT * FROM view_patient_doctors;
   SELECT * FROM view_upcoming_appointments;
   SELECT * FROM view_unpaid_bills;
   SELECT * FROM view_patient_history;
   ```

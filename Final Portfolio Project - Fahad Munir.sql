--
use portfolio_project;

select *
from virginia_patient;

set sql_safe_updates =0;

update virginia_patient
set ScheduledDay = str_to_date(ScheduledDay, "%c/%e/%Y");

update virginia_patient
set AppointmentDay = str_to_date(AppointmentDay, "%c/%e/%Y");


-- Basic SQL & Data Retrieval
-- 1.	Retrieve all columns from the Appointments table.

select *
from virginia_patient;

-- 2.	List the first 10 appointments where the patient is older than 60

-- I have used order by Function on Age  in decending Order to get top 10 patients with highest age and then placed a limit of 10

select *
from virginia_patient
where age > 60
order by age desc
limit 10;

-- 3.	Show the unique neighborhoods from which patients came.

select distinct neighbourhood
from virginia_patient;

-- 4.	Find all female patients who received an SMS reminder. Give count of them

select count(*)
from virginia_patient
where (Gender = "Female") and (SMS_received = 1);


-- 5.	Display all appointments scheduled on or after '2023-05-01' and before '2023-06-01'.

select *
from virginia_patient
where ScheduledDay between '2023-05-01' and  '2023-06-01';


-- Data Modification & Filtering
-- 6.	Update the 'Showed_up' status to 'Yes' where it is null or empty

select showed_up
from virginia_patient
where showed_up = '';

set sql_safe_updates =0;

update  virginia_patient
set showed_up = 'Yes'
where showed_up = '';



-- 7.	Add a new column AppointmentStatus using a CASE statement:
-- ○	'No Show' if Showed_up = 'No'

-- ○	'Attended' otherwise


alter table virginia_patient
add column AppointmentStatus varchar(20) as
							 (case when showed_up = 'No' then 'No Show'
									else 'Attended'
									end);


-- 8.	Filter appointments for diabetic patients with hypertension

select AppointmentDay
from virginia_patient
where (Diabetes = 1 and Hypertension = 1);


-- 9.	Order the records by Age in descending order and show only the top 5 oldest patients.

select *
from virginia_patient
order by Age desc
limit 5;


-- 10.	Limit results to the first 5 appointments for patients under age 18.

select *
from virginia_patient
where Age < 18
limit 5;


-- Aggregation & Grouping

-- 11.	Find the average age of patients for each gender.

select Gender,avg(Age)
from virginia_patient
group by Gender;

-- 12.	Count how many patients received SMS reminders, grouped by Showed_up status


select Showed_up, count(Showed_up)
from virginia_patient
where SMS_received = "1"
group by Showed_up;

-- 13.	Count no-show appointments in each neighborhood using GROUP BY.

select Neighbourhood,count(AppointmentStatus)
from virginia_patient
where AppointmentStatus = 'No Show'
group by Neighbourhood;

-- 14.	Show neighborhoods with more than 100 total appointments (HAVING clause).

select count(AppointmentDay),Neighbourhood
from virginia_patient
group by Neighbourhood
having count(AppointmentDay) > 100;

-- 15.	Use CASE to calculate the total number of:

-- ○	children (Age < 12)

-- ○	adults (Age BETWEEN 12 AND 60)

-- ○	seniors (Age > 60)


select case when Age < 12 then 'Children'
		  when Age between 12 and 60 then 'Adult'
          when Age > 60 then 'Seniors'
           end as age_gp , count(*)
from virginia_patient
group by age_gp; 
	

-- Window Functions
-- 16.	  Tracks how appointments accumulate over time in each neighbourhood.
--  (Running Total of Appointments per Day)  In simple words: How many appointments were there each
--  day and how do the total appointments keep adding up over time in each neighborhood?



select *
from virginia_patient;

select Neighbourhood,count(AppointmentDay)
from virginia_patient
group by Neighbourhood;

select AppointmentDay, Neighbourhood,
		count(AppointmentDay), sum(AppointmentDay) over(partition by Neighbourhood order by AppointmentDay)
from virginia_patient
group by Neighbourhood , AppointmentDay
order by Neighbourhood, AppointmentDay;

-- 17.	Use Dense_Rank() to rank patients by age within each gender group

select *,Age,Gender
from virginia_patient
group by Gender
order by Age;


select PatientId,Gender,Age,ScheduledDay,AppointmentDay, Neighbourhood,
		dense_rank () over (partition by Gender order by Age) 
        
        from virginia_patient;


-- 18.	How many days have passed since the last appointment in the same neighborhood? (Hint: DATEDIFF and Lag)
--   (This helps to see how frequently appointments are happening in each neighborhood.)

select Neighbourhood,AppointmentDay,
		lag (AppointmentDay) over (partition by Neighbourhood order by AppointmentDay)
from virginia_patient;

select Neighbourhood,AppointmentDay,
		Datediff(AppointmentDay,lag (AppointmentDay) over (partition by Neighbourhood order by AppointmentDay))
        
from virginia_patient;

-- 19.	Which neighborhoods have the highest number of missed appointments?
--  Use DENSE_RANK() to rank neighborhoods based on the number of no-show appointments.


with t as (
	select Neighbourhood,AppointmentDay,Showed_up
	from virginia_patient 
	where Showed_up = 'No'

)

select Neighbourhood,AppointmentDay,Showed_up,
		dense_rank() over (partition by Neighbourhood order by AppointmentDay )
        
from t;


-- 20.	 Are patients more likely to miss appointments on certain days of the week?
-- Steps to follow for question # 20
-- •	(Use the AppointmentDay column in function dayname() to extract the day name (like Monday, Tuesday, etc.).
-- •	Count how many appointments were scheduled, how many showed up (showed_up = "yes") and how many were missed (Showed_up = 'No') on each day.
-- •	Calculate the percentage of shows and no-shows for better comparison between days. 
-- •	Formula: (count of Showed_up = 'yes' / total appointment count ) * 100, Use round function to  show upto two decimal points
-- •	Sort the result by No_Show_Percent in descending order to see the worst-performing days first.


select AppointmentDay, dayname (AppointmentDay) as day_of_wk
from virginia_patient;

SELECT 
    DAYNAME(AppointmentDay) AS Day, 
    COUNT(AppointmentDay) AS TotalAppointments,
    COUNT(CASE WHEN Showed_up = 'yes' THEN 1 END) AS TookAppt,
    COUNT(CASE WHEN Showed_up = 'No' THEN 1 END) AS MissedAppt,
	ROUND(COUNT(CASE WHEN Showed_up = 'yes' THEN 1 END) /COUNT(AppointmentDay)  * 100) AS Percent_TookAppt,
    ROUND(COUNT(CASE WHEN Showed_up = 'no' THEN 1 END)/ COUNT(AppointmentDay) * 100) AS Percent_MissedAppt
FROM virginia_patient
GROUP BY DAYNAME(AppointmentDay)
ORDER BY Percent_MissedAppt DESC;

/*Comments: This query analyses appointment attendance by day of the week. It extracts the day name from AppointmentDay, counts total appointments, 
how many were attended, and how many were missed. It then calculates the percentage of shows and no-shows per day, rounding to two decimals, and 
sorts the days to highlight those with the highest no-show rates first.*/







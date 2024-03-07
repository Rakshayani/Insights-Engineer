CREATE DATABASE projects_hr;

USE projects_hr;

SELECT * FROM hr;

-- DATA CLEANING AND PREPROCESSING --

ALTER TABLE hr 
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

DESCRIBE hr

SET sql_safe_updates = 0;

-- change data format and datatype of birthdate column --

UPDATE hr
SET birthdate = CASE
        WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
        WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
        ELSE NULL
        END;
        
ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- change data format and datatype of hire_date column --

UPDATE hr
SET hire_date = CASE
        WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
        WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
        ELSE NULL
        END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- change data format and datatype of termdate column --

UPDATE hr
SET termdate = date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate !='';

UPDATE hr
SET termdate = NULL
WHERE termdate = '';

-- create age column --

ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr
SET age = timestampdiff(YEAR,birthdate,curdate())

SELECT min(age), max(age) FROM hr

-- 1. What is the gender breakdown of employees in the company --

SELECT * FROM hr

SELECT gender, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY gender;

-- 2. What is the race breakdown of employees in the company --

SELECT race, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY race;

-- 3. What is the age distribution of employees in the company --

SELECT
	CASE 
      WHEN age>=18 AND age<=24 THEN '18-24'
      WHEN age>=25 AND age<=34 THEN '25-34'
      WHEN age>=35 AND age<=44 THEN '35-44'
      WHEN age>=45 AND age<=54 THEN '45-54'
      WHEN age>=55 AND age<=64 THEN '55-64'
      ELSE '64+'
	END AS age_group,
    COUNT(*) AS count
    FROM hr
    WHERE termdate IS NULL
    GROUP BY age_group
    ORDER BY age_group

-- 4. How many employees work at HR vs remote --

SELECT location,COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY location;

-- 5. What is the average length of employment who have been terminated. --

SELECT ROUND(AVG(year(termdate)-year(hire_date)),0) AS length_of_emp
FROM hr
WHERE termdate IS NOT NULL AND termdate <= curdate()

-- 6. How does the gender distribution vary across dept. and job titles. - 

SELECT department,jobtitle,gender,COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender

SELECT department,gender,COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender

-- 7. What is the distribution of job titles across the company. --

SELECT jobtitle, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY jobtitle

-- 8. Which dept. has the higher termination rate. --

SELECT department, 
    COUNT(*) AS total_count,
    COUNT( CASE 
               WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
               END) AS terminated_count,
	ROUND((COUNT( CASE 
               WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1
               END)/COUNT(*))*100,2) AS termination_rate
	FROM hr
    GROUP BY department
    ORDER BY termination_rate DESC
    
-- 9. What is the distribution of employees across location_state and city. --

SELECT location_state, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL 
GROUP BY location_state

SELECT location_city, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL 
GROUP BY location_city

-- 10. 	How has the companies employees count changed over time based on hire and termination date.--

SELECT * FROM hr

SELECT
    year,
    hires,
    terminations,
    hires - terminations AS net_change,
    (terminations / hires) * 100 AS change_percent
FROM (
    SELECT
        YEAR(hire_date) AS year,
        COUNT(*) AS hires,
        SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM hr
    WHERE hire_date IS NOT NULL 
    GROUP BY YEAR(hire_date)
) AS subquery
WHERE year IS NOT NULL  
GROUP BY year
ORDER BY year;

-- 11. What is the tenure distribution for each dept.

SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM hr
WHERE termdate IS NOT NULL AND termdate<= curdate()
GROUP BY department

-- 12. Age distribution across dept. --

SELECT
    department,
    SUM(CASE WHEN age_group = '18-25' THEN 1 ELSE 0 END) AS age_18_25,
    SUM(CASE WHEN age_group = '26-35' THEN 1 ELSE 0 END) AS age_26_35,
    SUM(CASE WHEN age_group = '36-45' THEN 1 ELSE 0 END) AS age_36_45,
    SUM(CASE WHEN age_group = '46-55' THEN 1 ELSE 0 END) AS age_46_55,
    SUM(CASE WHEN age_group = '56+' THEN 1 ELSE 0 END) AS age_56_plus
FROM (
    SELECT
        department,
        DATEDIFF(CURRENT_DATE, birthdate) / 365.25 AS age,
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            ELSE '56+'
        END AS age_group
    FROM
        hr
) AS age_data
GROUP BY
    department;

-- Year wise termination --

SELECT YEAR(termdate) AS termination_year, COUNT(*) AS termination_count
FROM hr
WHERE termdate IS NOT NULL
GROUP BY YEAR(termdate)
ORDER BY termination_year;

-- AVG revenue by dept. --

SELECT department, SUM(revenue) AS total_revenue, AVG(revenue) AS avg_revenue
FROM hr
WHERE revenue IS NOT NULL 
GROUP BY department;

-- Job Title Analysis: --

SELECT
  jobtitle,
  COUNT(*) AS employee_count
FROM
  hr
GROUP BY
  jobtitle;

-- tenure analysis --

SELECT
  department,
  AVG(DATEDIFF(termdate, hire_date)) AS avg_tenure
FROM
  hr
WHERE
  termdate IS NOT NULL
GROUP BY
  department;

-- location Analysis --
SELECT
  location_city,
  location_state,
  COUNT(*) AS employee_count
FROM
  hr
GROUP BY
  location_city, location_state;

-- emp turnover --

SELECT
  YEAR(hire_date) AS hire_year,
  COUNT(*) AS hires,
  SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
FROM
  hr
WHERE
  hire_date IS NOT NULL
GROUP BY
  hire_year;

-- Termination count by gender --

SELECT
  gender,
  COUNT(*) AS termination_count
FROM
  hr
WHERE
  termdate IS NOT NULL
GROUP BY
  gender;

-- problem 1

SELECT
    job_schedule_type,
    AVG(salary_year_avg) AS year_avg_salary,
    AVG(salary_hour_avg) AS hour_avg_salary
FROM   
    job_postings_fact
WHERE 
    job_posted_date::date  > '2023-06-01'
GROUP BY
    job_schedule_type
ORDER BY
    job_schedule_type;

-- problem 2

SELECT
    COUNT(*) AS number_jobs,
    EXTRACT(MONTH FROM job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST') AS month
FROM    
    job_postings_fact
GROUP BY
    month
ORDER BY  
    month;

-- problem 3

SELECT
    COUNT(jobs.job_id) AS number_jobs,
    companies.name
FROM    
    job_postings_fact AS jobs
INNER JOIN company_dim AS companies
    ON jobs.company_id = companies.company_id
WHERE
    jobs.job_health_insurance = TRUE AND 
    EXTRACT(QUARTER FROM jobs.job_posted_date) = 2
GROUP BY 
    companies.name
HAVING 
    COUNT(jobs.job_id) >= 1
ORDER BY 
    number_jobs DESC;

-- PRACTICE PROBLEM 6

CREATE TABLE january_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 1;

CREATE TABLE fabruary_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 2;

CREATE TABLE march_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE 
        EXTRACT(MONTH FROM job_posted_date) = 3;

-- CASE EXPRESSION 

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact
WHERE 
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;

-- problem 1

SELECT
    job_id,
    job_title,
    salary_year_avg,
    CASE
        WHEN salary_year_avg >= 100000 THEN 'high salary'
        WHEN salary_year_avg >= 60000 THEN 'Standard salary'
        ELSE 'Low salary'
    END AS salary_category
FROM
    job_postings_fact
WHERE 
    salary_year_avg IS NOT NULL AND
    job_title_short = 'Data Analyst'
ORDER BY 
    salary_category DESC;

-- problem 2

/*
SELECT
    COUNT(DISTINCT company_id) AS number_of_unique_companies,
    CASE
        WHEN job_work_from_home = TRUE THEN 'remote'
        ELSE 'onsite'
    END AS work_from_home 
FROM job_postings_fact
GROUP BY
    job_work_from_home;
*/

SELECT
    COUNT(DISTINCT CASE
                        WHEN job_work_from_home = TRUE THEN company_id END) AS wfh_companies,
    COUNT(DISTINCT CASE
                        WHEN job_work_from_home = FALSE THEN company_id END) AS non_wfh
FROM
    job_postings_fact; 

-- problem 3

SELECT
    job_id,
    salary_year_avg,
    CASE
        WHEN job_title ILIKE '%Senior%' THEN 'Senior'
        WHEN job_title ILIKE '%Manager%' OR job_title ILIKE '%Lead%' THEN 'Lead/Manager'
        WHEN job_title ILIKE '%Junior%' OR job_title ILIKE '%Entry%' THEN 'Junior/Entry'
        ELSE 'Not Specified'
    END AS experience_level,
    CASE
        WHEN job_work_from_home = TRUE THEN 'Yes'
        ELSE 'No'
    END AS remote_option
FROM
    job_postings_fact
WHERE
    salary_year_avg IS NOT NULL
ORDER BY
    job_id;

-- SubQueries and CTEs

SELECT *
FROM (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
) AS january_jobs;

WITH january_jobs AS (
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1
)
SELECT *
FROM january_jobs;


SELECT 
    name AS company_name
FROM 
    company_dim
WHERE 
    company_id IN(
        SELECT 
            company_id
        FROM job_postings_fact
        WHERE 
            job_no_degree_mention = TRUE
)
ORDER BY
    company_name;

/*
Code without Subquery

SELECT 
    companies.name AS name
FROM 
    company_dim AS companies
LEFT JOIN job_postings_fact AS jobs
    ON companies.company_id = jobs.company_id
WHERE 
    job_no_degree_mention = TRUE
GROUP BY
    companies.name
ORDER BY 
    companies.name;
*/

WITH company_job_count AS (
    SELECT
        company_id,
        COUNT(*) AS total_jobs
    FROM    
        job_postings_fact
    GROUP BY
        company_id
)

SELECT 
    company_dim.name AS company_name,
    company_job_count.total_jobs
FROM 
    company_dim
LEFT JOIN company_job_count 
    ON company_job_count.company_id = company_dim.company_id; 

-- problem 1

SELECT
    skills_dim.skills
FROM skills_dim
INNER JOIN (  -- Об’єднуємо з підзапитом, який рахує кількість згадок кожного скіла
            SELECT 
                skill_id,   -- Ідентифікатор скіла
                COUNT(job_id) AS count_skill  -- Підрахунок, скільки разів цей скіл згадувався у job postings
            FROM                -- Таблиця зв’язку "вакансія — скіл"
                skills_job_dim
            GROUP BY        -- Групуємо по скілу, щоб порахувати кожен окремо
                skill_id
            ORDER BY 
                count_skill DESC    -- Сортуємо за кількістю згадок — від найбільшої до найменшої
            LIMIT 5
        ) AS top_skills
ON skills_dim.skill_id = top_skills.skill_id
ORDER BY
    top_skills.count_skill DESC;      -- Фінальне сортування: від найпопулярнішого до менш популярного

-- problem 2

SELECT
    company_id,
    name,
    CASE
        WHEN job_count > 50 THEN 'Large'  -- Якщо вакансій більше 50, то компанія "Велика"
        WHEN job_count > 10 THEN 'Medium'  -- Якщо вакансій від 11 до 50, то компанія "Середня"
        ELSE 'Small'  -- Якщо вакансій 10 або менше, то компанія "Мала"
    END AS size_category
FROM (
        SELECT
            company_dim.company_id,  -- Вибираємо ID компанії
            company_dim.name,  -- Вибираємо назву компанії
            COUNT(job_postings_fact.job_id) AS job_count  -- Підраховуємо кількість вакансій для кожної компанії
        FROM
            company_dim  -- З таблиці компаній
        INNER JOIN job_postings_fact  -- З'єднуємо з таблицею вакансій
            ON company_dim.company_id = job_postings_fact.company_id  -- Встановлюємо зв'язок за ID компанії
        GROUP BY
            company_dim.company_id,  -- Групуємо за ID компанії, щоб підрахувати вакансії для кожної компанії окремо
            company_dim.name  -- Також групуємо за назвою компанії
) AS company_job_count;  -- Підзапит, який рахує вакансії для кожної компанії

-- problem 3

/*
SELECT
    company_dim.name
FROM company_dim
INNER JOIN(
        SELECT 
            company_id,
            AVG(salary_year_avg) AS avg_company_salary
        FROM job_postings_fact
        WHERE 
            salary_year_avg IS NOT NULL
        GROUP BY
            company_id
) AS company_avg_salary 
    ON company_dim.company_id = company_avg_salary.company_id
WHERE company_avg_salary.avg_company_salary > (
                                             SELECT
                                                 AVG(salary_year_avg)
                                             FROM job_postings_fact
);
*/

SELECT 
    company_salary.name 
FROM(     -- Підзапит, який обчислює середню зарплату по кожній компанії
    SELECT
        companies.name AS name,
        companies.company_id AS id_company,
        AVG(salary_year_avg) AS company_salary  -- Середня зарплата в цій компанії
    FROM job_postings_fact
    INNER JOIN company_dim AS companies   -- З'єднуємо таблицю з назвами компаній
        ON job_postings_fact.company_id = companies.company_id
    GROUP BY 
        id_company   -- Групуємо по ID компанії, щоб порахувати середню
) AS company_salary
WHERE company_salary.company_salary > (
                                        SELECT AVG(salary_year_avg)   -- Підзапит: обчислює загальну середню зарплату
                                        FROM job_postings_fact
);

-- CTEs
-- problem 1

WITH diverse_job AS (
    SELECT 
        company_id,
        COUNT(DISTINCT job_title) AS unique_title
    FROM job_postings_fact
    GROUP BY
        company_id
)

SELECT 
    company_dim.name,
    diverse_job.unique_title
FROM company_dim
INNER JOIN diverse_job 
    ON company_dim.company_id = diverse_job.company_id
ORDER BY
    unique_title DESC   -- Сортуємо результати за кількістю унікальних вакансій у порядку спадання (від найбільш різноманітних до менш різноманітних).
LIMIT 10;

-- problem 2

WITH country_salary AS(
    SELECT
        job_country,
        AVG(salary_year_avg) AS avg_salary
    FROM job_postings_fact
    GROUP BY
        job_country
)

SELECT
    job_postings_fact.job_id,
    job_postings_fact.job_title,
    company_dim.name AS company_name,
    job_postings_fact.salary_year_avg AS salary_rate,
    CASE 
        WHEN job_postings_fact.salary_year_avg > country_salary.avg_salary THEN 'Above Average'
        ELSE 'Below Average'
    END AS rate_salary,
    EXTRACT(MONTH FROM job_postings_fact.job_posted_date) AS posted_month
FROM job_postings_fact
INNER JOIN company_dim
    ON job_postings_fact.company_id = company_dim.company_id
INNER JOIN country_salary
    ON job_postings_fact.job_country = country_salary.job_country
ORDER BY
   job_postings_fact.job_id;

-- problem 3

WITH unique_skills AS ( 

    /* НЕ ВРАХОВУЄ КОМПАНІЇ БЕЗ ВАКАНСІЙ
    SELECT 
        jpf.company_id,
        COUNT(DISTINCT sj.skill_id) AS uni_skill -- рахує унікальні навички для кожної компанії.
    FROM job_postings_fact AS jpf
    LEFT JOIN skills_job_dim AS sj 
        ON jpf.job_id = sj.job_id
    GROUP BY 
        jpf.company_id */

    SELECT 
        companies.company_id,
        COUNT(DISTINCT skills_to_job.skill_id) AS uni_skill
  FROM
        company_dim AS companies 
  LEFT JOIN job_postings_fact AS job_postings 
    ON companies.company_id = job_postings.company_id
  LEFT JOIN skills_job_dim AS skills_to_job 
    ON job_postings.job_id = skills_to_job.job_id
  GROUP BY
    companies.company_id  
), 

    high_salary AS (
    SELECT 
        cd.company_id,
        MAX(jpf.salary_year_avg) AS max_salary
    FROM
        company_dim AS cd
    LEFT JOIN job_postings_fact AS jpf
        ON jpf.company_id = cd.company_id
    WHERE
        jpf.job_id IN (SELECT job_id FROM skills_job_dim)
    GROUP BY
        cd.company_id
)

SELECT
    cmd.company_id,
    cmd.name,
    us.uni_skill,
    hs.max_salary
FROM company_dim AS cmd
LEFT JOIN unique_skills AS us 
    ON us.company_id = cmd.company_id
LEFT JOIN high_salary AS hs 
    ON cmd.company_id = hs.company_id
ORDER BY
    cmd.name;


-- PRACTICE PROBLEM 7

WITH remote_job_skills AS (
SELECT
    skill_id,
    COUNT(*) AS skill_count
FROM
    skills_job_dim AS skills_to_job
INNER JOIN job_postings_fact AS job_postings
    ON skills_to_job.job_id = job_postings.job_id
WHERE job_postings.job_work_from_home = TRUE
GROUP BY
    skill_id
)

SELECT 
    skills.skill_id,
    skills AS skill_name,
    skill_count
FROM remote_job_skills
INNER JOIN skills_dim AS skills
    ON skills.skill_id = remote_job_skills.skill_id
ORDER BY
    skill_count DESC
LIMIT 5;

-- UNION Operators

 SELECT 
	job_title_short,
	company_id,
	job_location
FROM
	january_jobs

UNION ALL

SELECT 
	job_title_short,
	company_id,
	job_location
FROM
	fabruary_jobs

UNION ALL

SELECT 
	job_title_short,
	company_id,
	job_location
FROM
	march_jobs

-- PRACTICE problem 8

SELECT 
    quarter1_job_postings.job_title_short,
    quarter1_job_postings.job_location,
    quarter1_job_postings.job_via,
    quarter1_job_postings.job_posted_date::DATE,
    quarter1_job_postings.salary_year_avg
    FROM (
    SELECT *
    FROM january_jobs
    UNION ALL 
    SELECT *
    FROM fabruary_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS quarter1_job_postings
WHERE
    quarter1_job_postings.salary_year_avg > 70000 AND
    quarter1_job_postings.job_title_short = 'Data Analyst'
ORDER BY
    quarter1_job_postings.salary_hour_avg DESC

-- problem 1

SELECT
    job_id,
    job_title,
    'With Salary info' AS salary_info
FROM 
    job_postings_fact
WHERE 
    salary_hour_avg IS NOT NULL OR
    salary_year_avg IS NOT NULL
UNION ALL
SELECT
    job_id,
    job_title,
    'Without Salary info' AS salary_info
FROM 
    job_postings_fact
WHERE 
    salary_hour_avg IS NULL AND
    salary_year_avg IS NULL
ORDER BY 
	salary_info DESC, 
	job_id;

-- problem 2
SELECT
    quarter1.job_id,
    quarter1.job_title_short,
    quarter1.job_location,
    quarter1.job_via,
    skills.skills,
    skills.type
FROM (
        SELECT *
        FROM january_jobs
        UNION ALL 
        SELECT *
        FROM fabruary_jobs
        UNION ALL
        SELECT *
        FROM march_jobs
) AS quarter1
LEFT JOIN skills_job_dim AS skills_job
    ON skills_job.job_id = quarter1.job_id
LEFT JOIN skills_dim AS skills
    ON skills.skill_id = skills_job.skill_id
WHERE 
    quarter1.salary_year_avg > 70000;

-- problem 3

SELECT
    skills.skills,
    COUNT(quarter1.job_id) AS job_count,
    EXTRACT(MONTH FROM quarter1.job_posted_date) AS posted_month,
    EXTRACT(YEAR FROM quarter1.job_posted_date) AS posted_year
FROM (
    SELECT *
    FROM january_jobs
    UNION ALL 
    SELECT *
    FROM fabruary_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS quarter1
INNER JOIN skills_job_dim AS skills_job
    ON skills_job.job_id = quarter1.job_id
INNER JOIN skills_dim AS skills
    ON skills.skill_id = skills_job.skill_id
GROUP BY
    skills.skills,
    EXTRACT(MONTH FROM quarter1.job_posted_date),
    EXTRACT(YEAR FROM quarter1.job_posted_date)
ORDER BY
    skills.skills,
    posted_year,
    posted_month;
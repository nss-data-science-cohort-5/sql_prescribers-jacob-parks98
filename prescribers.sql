SELECT *
FROM prescriber
LIMIT 5;

 /* 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)?
 Report the npi and the total number of claims.
    b. Repeat the above, but this time report the nppes_provider_first_name,
	nppes_provider_last_org_name,  specialty_description, and the total number of claims. */
	
--a.
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1; 

-- npi 1881634483 had the highest total number of claims

--b. 
SELECT prescription.npi,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY prescription.npi,
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Bruce Pendley had the highest number of claims

/* 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

    b. Which specialty had the most total number of claims for opioids?

    c. **Challenge Question:** Are there any specialties that appear in the prescriber 
	table that have no associated prescriptions in the prescription table?

    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
	For each specialty, report the percentage of total claims by that specialty which are for opioids.
	Which specialties have a high percentage of opioids?
*/

--a
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

--Family Practice had the highest number of total claims

--b. 
SELECT *
FROM drug
LIMIT 15;

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

--Nurse practitioner had the most claims for opioids

--c.
SELECT DISTINCT specialty_description
FROM prescriber
WHERE specialty_description NOT IN 
	(SELECT specialty_description
	FROM prescription
	INNER JOIN prescriber
	USING (npi));

-- Yes, there are 15 specialties that have no appearance in the prescription table.

--d. For each specialty, report the percentage of total claims by that specialty which are for opioids.
	--Which specialties have a high percentage of opioids?
	
SELECT 
	specialty_description, 
	ROUND(SUM(opioid_claims)/SUM(total_claim_count) * 100.0 , 2) AS percent_opioid
FROM
(SELECT specialty_description, total_claim_count, drug_name, opioid_drug_flag,
	CASE WHEN opioid_drug_flag = 'N' THEN 0
	ELSE total_claim_count END AS opioid_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)) AS opioid_claims_table
GROUP BY specialty_description
ORDER BY percent_opioid DESC;

--Vamsi
WITH 
	cte_1 AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS total_opioid_claims
		FROM prescriber
		JOIN prescription
		USING(npi)
		JOIN drug
		USING(drug_name)
		WHERE opioid_drug_flag = 'Y'
		GROUP BY specialty_description, opioid_drug_flag
),
	cte_2 AS (
		SELECT 
			specialty_description,
			SUM(total_claim_count) AS total_claims
		FROM prescriber
		JOIN prescription
		USING(npi)
		GROUP BY specialty_description	
)
SELECT 
	specialty_description,
	ROUND(total_opioid_claims / total_claims * 100.0, 2) AS opioid_pct
FROM cte_1
JOIN cte_2
USING(specialty_description)
ORDER BY opioid_pct DESC

--Alex
WITH
	all_drug
	AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS all_drug_claim
		FROM prescription
		LEFT JOIN prescriber
		USING (npi)
		LEFT JOIN drug
		USING(drug_name)
		GROUP BY specialty_description
	),
	opioid_drug
	AS (
		SELECT 
			specialty_description, 
			SUM(total_claim_count) AS opioid_claim
		FROM prescription
		LEFT JOIN prescriber
		USING (npi)
		LEFT JOIN drug
		USING(drug_name)
		WHERE opioid_drug_flag = 'Y'
		GROUP BY specialty_description
	)
SELECT *, COALESCE(ROUND(opioid_claim/all_drug_claim*100,2),0) AS opioid_pct
FROM all_drug
LEFT JOIN opioid_drug
USING (specialty_description)
ORDER BY opioid_pct DESC;



-- Case manager and Orthapedic Surgery have high percentage of opioid claims.

/* 3. a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day? 
	**Bonus: Round your cost per day column to 2 decimal places.
	Google ROUND to see how this works. */
	
--a.
SELECT generic_name, total_drug_cost --, MAX(total_drug_cost)
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE generic_name = 'PEN NEEDLE, DIABETIC'
--GROUP BY generic_name
--ORDER BY MAX(total_drug_cost) DESC;


SELECT generic_name,COUNT(DISTINCT drug_name) AS count
FROM drug
GROUP BY generic_name
ORDER BY count DESC;

SELECT drug_name, generic_name, total_drug_cost
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE generic_name = 'PEN NEEDLE, DIABETIC'
ORDER BY total_drug_cost DESC


--Pirfenidone had the highest cost

--Alex answer correct
SELECT generic_name, SUM(total_drug_cost)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC;


--b. 
SELECT DISTINCT generic_name, ROUND(total_drug_cost/total_day_supply, 2) AS drug_cost_per_day
FROM prescription
INNER JOIN drug
USING (drug_name)
ORDER BY drug_cost_per_day DESC;

--IMMUN GLOB C(IGG)/GLY/IGA OV50 has the highest cost per day

--Alex 
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2)
FROM prescription
LEFT JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC;


/* 4. a. For each drug in the drug table, return the drug name and then a column named
'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic'
for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

    b. Building off of the query you wrote for part a, 
	determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
	Hint: Format the total costs as MONEY for easier comparision. */
	
--a.
SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END
	AS drug_type
FROM drug;

--Vamsi using CAST
SELECT sub.drug_type, CAST(SUM(total_drug_cost) AS money)
FROM prescription
LEFT JOIN
	(SELECT drug_name,
	   	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	         WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	         ELSE 'neither' END AS drug_type
	 FROM drug) AS sub
USING(drug_name)
GROUP BY sub.drug_type
ORDER BY SUM(total_drug_cost) DESC;


--b.
SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END
	AS drug_type,
	SUM(total_drug_cost) AS MONEY
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY MONEY DESC;

/* the drug type neither had the highest total drug cost. 
Opioids had a higher total cost than antibiotics */

/* 5. a. How many CBSAs are in Tennessee?
**Warning:** The cbsa table contains information for all states, not just Tennessee.

    b. Which cbsa has the largest combined population? Which has the smallest?
	Report the CBSA name and total population.

    c. What is the largest (in terms of population) county which is not included in a CBSA?
	Report the county name and population. */
	
--a
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--Alex
SELECT COUNT(DISTINCT cbsa)
FROM fips_county AS f
LEFT JOIN cbsa AS c
USING(fipscounty)
WHERE f.state = 'TN';


--There are 10 distinct cbsas in Tennessee

--b
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

-- Nashville-Davidson-Murfreesboro-Franklin has the highest total pop, Morristown has the lowest.

--Alex left Join
SELECT cbsaname, 
	   SUM(population) AS total_pop
FROM population
LEFT JOIN cbsa
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop;

--c.
SELECT county, state, SUM(population) AS total_pop
FROM fips_county
INNER JOIN population
USING(fipscounty)
WHERE county NOT IN 
(
	SELECT county
	FROM cbsa
	INNER JOIN fips_county
	USING(fipscounty)
	WHERE cbsaname LIKE '%TN%'
)
GROUP BY county,state
ORDER BY total_pop DESC;

--Sevier County is the largest county not in a cbsa

/* 6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. 
	Report the drug_name and the total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the
	drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber 
	first and last name associated with each row. */
	
--a
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

--b
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'Not Opioid' END AS opioid_or_not
FROM prescription
INNER JOIN drug
USING(drug_name)
WHERE total_claim_count > 3000;

--c
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'Not Opioid' END AS opioid_or_not,
	nppes_provider_first_name,
	nppes_provider_last_org_name
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count > 3000;

/* 7. The goal of this exercise is to generate a full list of all pain management specialists 
in Nashville and the number of claims they had for each opioid.
    a. First, create a list of all npi/drug_name combinations for pain management specialists 
	(specialty_description = 'Pain Managment') in the city of Nashville 
	(nppes_provider_city = 'NASHVILLE'), 
	where the drug is an opioid (opiod_drug_flag = 'Y').
	**Warning:** Double-check your query before running it. 
	You will likely only need to use the prescriber and drug tables.

    b. Next, report the number of claims per drug per prescriber.
	Be sure to include all combinations, whether or not the prescriber had any claims.
	You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count
	with 0. Hint - Google the COALESCE function. */
	
--a.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--b & c
SELECT p1.npi, d.drug_name, COALESCE(total_claim_count, 0) AS total_claims
FROM prescriber AS p1
CROSS JOIN drug AS d
FULL JOIN prescription AS p2
USING (drug_name,npi)
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
ORDER BY 3 DESC;


--Check if this worked, looks like it did
SELECT npi, drug_name, total_claim_count
FROM prescription
WHERE npi = '1932256898'
AND drug_name IN ('VICODIN','OXYCONTIN','FENTANYL')


--BONUS QUESTIONS
--1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE npi NOT IN 
(
	SELECT DISTINCT npi
	FROM prescription
)

--4458 prescribers appear in the prescriber table but not in  the prescription table

/*2.
    a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of 
	Family Practice.

    b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

    c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists?
	Combine what you did for parts a and b into a single query to answer this question. */
	
--a.
SELECT generic_name, SUM(total_claim_count)
FROM
(
	SELECT *
	FROM prescriber
	INNER JOIN prescription
	USING (npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Family Practice'
) AS drug_prescription_prescriber_table
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;

--Vamsi
SELECT generic_name
FROM prescription
LEFT JOIN prescriber
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5


--Alex
SELECT generic_name, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING (npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

--b
SELECT generic_name, SUM(total_claim_count)
FROM
(
	SELECT *
	FROM prescriber
	INNER JOIN prescription
	USING (npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Cardiology'
) AS drug_prescription_prescriber_table
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

--c
(SELECT generic_name
FROM
(
	SELECT *
	FROM prescriber
	INNER JOIN prescription
	USING (npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Cardiology'
) AS drug_prescription_prescriber_table
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
INTERSECT
(SELECT generic_name
FROM
(
	SELECT *
	FROM prescriber
	INNER JOIN prescription
	USING (npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE specialty_description = 'Family Practice'
) AS drug_prescription_prescriber_table
GROUP BY generic_name
ORDER BY SUM(total_claim_count) DESC
LIMIT 5);

--NONE

--Vamsi
WITH
    family_practice AS (
        SELECT 
            generic_name
        FROM prescription
        LEFT JOIN prescriber
        USING(npi)
        LEFT JOIN drug
        USING(drug_name)
        WHERE specialty_description = 'Family Practice'
        GROUP BY generic_name
        ORDER BY SUM(total_claim_count) DESC
        LIMIT 5
    ),
    cardiology AS (
        SELECT 
            generic_name
        FROM prescription
        LEFT JOIN prescriber
        USING(npi)
        LEFT JOIN drug
        USING(drug_name)
        WHERE specialty_description = 'Cardiology'
        GROUP BY generic_name
        ORDER BY SUM(total_claim_count) DESC
        LIMIT 5
    )
SELECT generic_name
FROM family_practice
INNER JOIN cardiology
USING(generic_name)


/* 3. Your goal in this question is to generate a list of the top prescribers in each of the major
metropolitan areas of Tennessee.
    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    b. Now, report the same for Memphis.
    c. Combine your results from a and b, along with the results for Knoxville and Chattanooga. */

--a
SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5;

--b
SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5;

--c
WITH nashville AS (
	SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5
),
memphis AS
 (
	 SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5
 ),
 knoxville AS (
	 SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5
 ),
 chattanooga AS (
	 SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5
 )
SELECT * 
FROM nashville
UNION
SELECT *
FROM memphis
UNION 
SELECT * 
FROM knoxville
UNION
SELECT *
FROM chattanooga
ORDER BY nppes_provider_city, total_claim_count;

/* Find all counties which had an above-average (for the state) number of overdose deaths in 2017.
Report the county name and number of overdose deaths. */

--correlated subquery

SELECT county, overdose_deaths
FROM fips_county AS f
INNER JOIN overdose_deaths AS od
USING(fipscounty)
WHERE overdose_deaths >
	(SELECT AVG(overdose_deaths) AS state_avg
	FROM overdose_deaths
	WHERE year = 2017
	AND f.fipscounty = od.fipscounty) 
AND year = 2017
ORDER BY overdose_deaths DESC;

--Alex
SELECT county, overdose_deaths
FROM overdose_deaths
LEFT JOIN fips_county
USING(fipscounty)
WHERE year = 2017
	AND overdose_deaths > (
		SELECT AVG(overdose_deaths)
		FROM overdose_deaths
		LEFT JOIN fips_county
		USING(fipscounty)
		WHERE year = 2017)
ORDER BY 2 DESC
;


/* 5.
    a. Write a query that finds the total population of Tennessee.
    b. Build off of the query that you wrote in part a to write a 
	query that returns for each county that county's name, its population, and the percentage of the 
	total population of Tennessee that is contained in that county. */
	
--a.
SELECT SUM(population) AS state_pop
FROM population;

--b.
SELECT county, 
	population, 
	population * 100.0 / (SELECT SUM(population) AS state_pop FROM population) AS state_pop_percentage
FROM fips_county
INNER JOIN population
USING (fipscounty)
ORDER BY state_pop_percentage DESC;

--need county name, claims, pop, opioid or not 
SELECT county, 
	population, 
	SUM(total_claim_count) AS total_opioid_claims
	
FROM prescription AS p1
INNER JOIN drug AS d
USING (drug_name)
INNER JOIN prescriber AS p2
ON p1.npi = p2.npi
INNER JOIN zip_fips AS z
ON p2.nppes_provider_zip5 = z.zip
INNER JOIN fips_county AS f 
USING (fipscounty)
INNER JOIN population 
USING (fipscounty)
WHERE opioid_drug_flag = 'Y'
GROUP BY county, population;

WITH total_claims AS (
	SELECT 
	county,
	population,
	SUM(total_claim_count) AS total_claims	
	FROM prescription AS p1
	INNER JOIN drug AS d
	USING (drug_name)
	INNER JOIN prescriber AS p2
	ON p1.npi = p2.npi
	INNER JOIN zip_fips AS z
	ON p2.nppes_provider_zip5 = z.zip
	INNER JOIN fips_county AS f 
	USING (fipscounty)
	INNER JOIN population 
	USING (fipscounty)
	GROUP BY county, population),
total_opioid_claims AS (
	SELECT county, 
	population, 
	SUM(total_claim_count) AS total_opioid_claims
	FROM prescription AS p1
	INNER JOIN drug AS d
	USING (drug_name)
	INNER JOIN prescriber AS p2
	ON p1.npi = p2.npi
	INNER JOIN zip_fips AS z
	ON p2.nppes_provider_zip5 = z.zip
	INNER JOIN fips_county AS f 
	USING (fipscounty)
	INNER JOIN population 
	USING (fipscounty)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY county, population)

SELECT *
FROM total_opioid_claims
INNER JOIN total_claims
USING(county, population)

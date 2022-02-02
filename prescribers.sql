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


/* 3. a. Which drug (generic_name) had the highest total drug cost?

    b. Which drug (generic_name) has the hightest total cost per day? 
	**Bonus: Round your cost per day column to 2 decimal places.
	Google ROUND to see how this works. */
	
--a.
SELECT generic_name, MAX(total_drug_cost)
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY generic_name
ORDER BY MAX(total_drug_cost) DESC;

--Pirfenidone had the highest cost

--b. 
SELECT DISTINCT generic_name, ROUND(total_drug_cost/total_day_supply, 2) AS drug_cost_per_day
FROM prescription
INNER JOIN drug
USING (drug_name)
ORDER BY drug_cost_per_day DESC;

--IMMUN GLOB C(IGG)/GLY/IGA OV50 has the highest cost per day


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
WHERE cbsaname LIKE '%TN';

--There are 6 distinct cbsas in Tennessee

--b
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

-- Nashville-Davidson-Murfreesboro-Franklin has the highest total pop, Morristown has the lowest.





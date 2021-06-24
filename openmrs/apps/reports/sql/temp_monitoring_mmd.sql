		SELECT distinct Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, DOB, Gender, age_group, 
				CASE
					WHEN datediff(latest_follow_up, max_observation) BETWEEN 56 AND 84 THEN 'MMD: 2 months'
					WHEN datediff(latest_follow_up, max_observation) BETWEEN 84 AND 112 THEN 'MMD: 3 months'
					WHEN datediff(latest_follow_up, max_observation) BETWEEN 112 AND 140 THEN 'MMD: 4 months'
					WHEN datediff(latest_follow_up, max_observation) BETWEEN 140 AND 168 THEN 'MMD: 5 months'
					WHEN datediff(latest_follow_up, max_observation) BETWEEN 168 AND 196 THEN 'MMD: 6 months'
					WHEN datediff(latest_follow_up, max_observation)    >=   196   THEN 'MMD: 7+ months'
					ELSE 'Other supply' 
				END as 'Program_Status'
		 FROM 
			   (select distinct patient.patient_id as Id,
											   patient_identifier.identifier as patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) as patientName,
											   floor(datediff(CAST('#endDate#' as DATE), person.birthdate)/365) as Age,
											   person.birthdate as DOB,
											   person.gender as Gender,
											   observed_age_group.name as age_group,
											   clients_fup_olap.max_observation,
											   clients_fup_olap.latest_follow_up

				from obs o
						-- e.g. CAME IN PREVIOUS 3 MONTHS AND WAS BEEN GIVEN A FOLLOW UP DATE THAN IS GREATER THAN  (4, 5, 6 MONHTS SUPPLY OF DRUGS)
						-- SELECT THE LATEST OBSERVATION FOR A PATIENT WHICH HAS A FOLLOW UP DATE THAT OVERLAPS THE CURRENT END DATE!!! Determine the duration of overlap to start with
						 INNER JOIN patient ON o.person_id = patient.patient_id
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.person_id in (
							select person_id
							from
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) < 0) as clients_with_overlap_follow_up
						 )

						 INNER JOIN 								
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
							     and oss.obs_datetime < cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) < 0 and 
								 datediff(latest_follow_up, max_observation) >= 56) as clients_fup_olap on o.person_id = clients_fup_olap.person_id
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages' AND 
					   clients_fup_olap.max_observation in (
							select oe.obs_datetime
							from obs oe
							where oe.concept_id = 3753 and oe.obs_datetime = o.obs_datetime	and oe.voided = 0	   
					   )
					   	-- Not seen in reporting period
					 AND o.person_id not in (
						select distinct os.person_id
						from obs os
						where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
						AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
					 )
					 -- Not initiated in reporting period
					 AND o.person_id not in (
						select distinct person_id
						from obs 
						where concept_id = 2249
						AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
					 )
					 AND o.person_id not in (
								select person_id 
								from person 
								where death_date <= cast('#endDate#' as date)
								and dead = 1
					 ))  as seen_prev_mmd
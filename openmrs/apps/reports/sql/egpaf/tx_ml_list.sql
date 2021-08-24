SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, Outcome, sort_order
FROM
(
			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'DIED' AS Outcome, sort_order
			FROM
							(select patient.patient_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order

							from obs o
									 INNER JOIN patient ON o.person_id = patient.patient_id
									 AND patient.voided = 0 AND o.voided = 0						 
									 AND o.person_id in (
										select person_id
										from 
											(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
											 from obs oss
											 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
											 group by p.person_id
											 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
									 )
									 AND o.person_id in (
											select person_id
											from 
												(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
												 from obs oss
												 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
												 and oss.obs_datetime < cast('#startDate#' as DATE)
												 group by p.person_id
												 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) <= 28) as On_ART_Beginning_Quarter
											UNION
											select person_id
											from obs oss
											where oss.concept_id = 2249 and oss.value_datetime >= cast('#startDate#' as DATE) and oss.value_datetime <= cast('#endDate#' as DATE)

									 )	 
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON
									 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
							   WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 AND o.person_id in (
											select person_id 
											from person 
											where death_date >= CAST('#startDate#' AS DATE) AND death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
							  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'TOUT' AS Outcome, sort_order
			FROM
							(select patient.patient_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order

							from obs o
									-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS
									-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
									 INNER JOIN patient ON o.person_id = patient.patient_id
									 AND patient.voided = 0 AND o.voided = 0						 
									 AND o.person_id in (
										select person_id
										from 
											(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
											 from obs oss
											 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
											 group by p.person_id
											 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
									 )
									 AND o.person_id in (
											select person_id
											from 
												(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
												 from obs oss
												 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
												 and oss.obs_datetime < cast('#startDate#' as DATE)
												 group by p.person_id
												 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) <= 28) as On_ART_Beginning_Quarter
											UNION
											select person_id
											from obs oss
											where oss.concept_id = 2249 and oss.value_datetime >= cast('#startDate#' as DATE) and oss.value_datetime <= cast('#endDate#' as DATE)
									 )
									 									 
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON
									 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
							   WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- Transfered Out to Another Site
									 AND o.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )

							   ) AS TxRttClients
							  ORDER BY TxRttClients.Age)		  

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'STOPPED' AS Outcome, sort_order
			FROM
							(select patient.patient_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order

							from obs o
									-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS
									-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
									 INNER JOIN patient ON o.person_id = patient.patient_id
									 AND patient.voided = 0 AND o.voided = 0						 
									 AND o.person_id in (
										select person_id
										from 
											(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
											 from obs oss
											 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
											 group by p.person_id
											 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
									 )
									 AND o.person_id in (
											select person_id
											from 
												(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
												 from obs oss
												 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
												 and oss.obs_datetime < cast('#startDate#' as DATE)
												 group by p.person_id
												 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) <= 28) as On_ART_Beginning_Quarter
											UNION
											select person_id
											from obs oss
											where oss.concept_id = 2249 and oss.value_datetime >= cast('#startDate#' as DATE) and oss.value_datetime <= cast('#endDate#' as DATE)
									 )
									 									 
									 -- NOT Transfered Out to Another Site
									 AND o.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )

									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON
									 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
							   WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- ART TREATMENT INTERRUPTION/REFUSED OR STOPPED
									 AND o.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 3701 
											AND os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'LFTU<3m' AS Outcome, sort_order
			FROM
							(select patient.patient_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order

							from obs o
									-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS
									-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
									 INNER JOIN patient ON o.person_id = patient.patient_id
									 AND patient.voided = 0 AND o.voided = 0						 
									 AND o.person_id in (
										select person_id
										from 
											(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
											 from obs oss
											 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
											 group by p.person_id
											 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
									 )
									 AND o.person_id in (
											select person_id
											from 
												(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
												 from obs oss
												 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
												 and oss.obs_datetime < cast('#startDate#' as DATE)
												 group by p.person_id
												 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) <= 28) as On_ART_Beginning_Quarter
											UNION
											select person_id
											from obs oss
											where oss.concept_id = 2249 and oss.value_datetime >= cast('#startDate#' as DATE) and oss.value_datetime <= cast('#endDate#' as DATE)
									 )									 
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON
									 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
							   WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART LESS THAN 3 MONTHS AGO
									 AND o.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#startDate#' AS DATE), os.value_datetime) BETWEEN 0 AND 90						
									 )
									 -- NOT Transfered Out to Another Site
									 AND o.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
					  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'LFTU>3m' AS Outcome, sort_order
			FROM
							(select patient.patient_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order

							from obs o
									-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS
									-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
									 INNER JOIN patient ON o.person_id = patient.patient_id
									 AND patient.voided = 0 AND o.voided = 0						 
									 AND o.person_id in (
										select person_id
										from 
											(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
											 from obs oss
											 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
											 group by p.person_id
											 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
									 )
									 AND o.person_id in (
											select person_id
											from 
												(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
												 from obs oss
												 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
												 and oss.obs_datetime < cast('#startDate#' as DATE)
												 group by p.person_id
												 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) <= 28) as On_ART_Beginning_Quarter
											UNION
											select person_id
											from obs oss
											where oss.concept_id = 2249 and oss.value_datetime >= cast('#startDate#' as DATE) and oss.value_datetime <= cast('#endDate#' as DATE)

									 )
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON
									 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
							   WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART MORE THAN 3 MONTHS AGO
									 AND o.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#startDate#' AS DATE), os.value_datetime) >= 90						
									 )	
									 -- NOT Transfered Out to Another Site
									 AND o.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
) AS treatment_mortality_and_loss
GROUP BY treatment_mortality_and_loss.Id
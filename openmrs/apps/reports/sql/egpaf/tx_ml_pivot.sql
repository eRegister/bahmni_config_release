SELECT Total_Aggregated_TxML.AgeGroup
		, Total_Aggregated_TxML.TOUT_M
		, Total_Aggregated_TxML.TOUT_F
		, Total_Aggregated_TxML.STOPPED_M
		, Total_Aggregated_TxML.STOPPED_F
		, Total_Aggregated_TxML.LFTU_LT_3_M
		, Total_Aggregated_TxML.LFTU_LT_3_F
		, Total_Aggregated_TxML.LFTU_GT_3_M
		, Total_Aggregated_TxML.LFTU_GT_3_F		
		, Total_Aggregated_TxML.DIED_M
		, Total_Aggregated_TxML.DIED_F
		, Total_Aggregated_TxML.Total

FROM (
			(SELECT TX_ML_DETAILS.age_group AS 'AgeGroup'
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_TOUT' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS TOUT_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_TOUT' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS TOUT_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_STOPPED' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS STOPPED_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_STOPPED' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS STOPPED_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_LFTU<3m' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS LFTU_LT_3_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_LFTU<3m' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS LFTU_LT_3_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_LFTU>3m' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS LFTU_GT_3_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_LFTU>3m' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS LFTU_GT_3_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_DIED' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS DIED_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TX_ML_DIED' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS DIED_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(1)) as 'Total'
					, TX_ML_DETAILS.sort_order
					
			FROM (

					(SELECT Id, Age, Gender, age_group, 'TX_ML_DIED' AS Outcome, sort_order
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order

									from obs o
											-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS -- NB: HAVE LIMITED THE PERIOD TO A QUARTER (90 DAYS)
											-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
											 INNER JOIN patient ON o.person_id = patient.patient_id
											 AND patient.voided = 0 AND o.voided = 0						 
											 AND o.person_id in (
												select person_id
												from 
													(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
													 from obs oss
													 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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
									   ) AS TxMLClients)
									  
					UNION

					(SELECT Id, Age, Gender, age_group, 'TX_ML_TOUT' AS Outcome, sort_order
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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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

					(SELECT Id, Age, Gender, age_group, 'TX_ML_STOPPED' AS Outcome, sort_order
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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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
									   ) AS TxMLClients)

					UNION

					(SELECT Id, Age, Gender, age_group, 'TX_ML_LFTU<3m' AS Outcome, sort_order
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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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
									   ) AS TxMLClients)
							  
					UNION

					(SELECT Id, Age, Gender, age_group, 'TX_ML_LFTU>3m' AS Outcome, sort_order
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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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
									   ) AS TxMLClients)
						) AS TX_ML_DETAILS
				GROUP BY TX_ML_DETAILS.age_group
				ORDER BY TX_ML_DETAILS.sort_order)


			UNION ALL


			(SELECT 'Total' AS AgeGroup
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_TOUT' AND Totals.Gender = 'M', 1, 0))) AS TOUT_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_TOUT' AND Totals.Gender = 'F', 1, 0))) AS TOUT_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_STOPPED' AND Totals.Gender = 'M', 1, 0))) AS STOPPED_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_STOPPED' AND Totals.Gender = 'F', 1, 0))) AS STOPPED_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_LFTU<3m' AND Totals.Gender = 'M', 1, 0))) AS LFTU_LT_3_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_LFTU<3m' AND Totals.Gender = 'F', 1, 0))) AS LFTU_LT_3_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_LFTU>3m' AND Totals.Gender = 'M', 1, 0))) AS LFTU_GT_3_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_LFTU>3m' AND Totals.Gender = 'F', 1, 0))) AS LFTU_GT_3_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_DIED' AND Totals.Gender = 'M', 1, 0))) AS DIED_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TX_ML_DIED' AND Totals.Gender = 'F', 1, 0))) AS DIED_F
					, IF(Totals.Id IS NULL, 0, SUM(1)) as 'Total'
					, 99 AS 'sort_order'
					
			FROM

					(SELECT  Total_TxML.Id
								, Total_TxML.Age
								, Total_TxML.Gender
								, Total_TxML.Outcome
							
					FROM

					(
				

					(SELECT Id, Age, Gender, 'TX_ML_DIED' AS Outcome
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender

									from obs o
											-- PATIENTS WITH NO CLINICAL CONTACT OR ARV PICK-UP FOR GREATER THAN 28 DAYS -- NB: HAVE LIMITED THE PERIOD TO A QUARTER (90 DAYS)
											-- SINCE THEIR LAST EXPECTED CONTACT WHO RESTARTED ARVs WITHIN THE REPORTING PERIOD
											 INNER JOIN patient ON o.person_id = patient.patient_id
											 AND patient.voided = 0 AND o.voided = 0						 
											 AND o.person_id in (
												select person_id
												from 
													(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
													 from obs oss
													 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									   WHERE o.person_id in (
													select person_id 
													from person 
													where death_date >= CAST('#startDate#' AS DATE) AND death_date <= CAST('#endDate#' AS DATE)
													and dead = 1
											 )
									   ) AS TxMLClients)
									  
					UNION

					(SELECT Id, Age, Gender, 'TX_ML_TOUT' AS Outcome
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender

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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
											 )						 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									   WHERE 
											 -- Transfered Out to Another Site
											 o.person_id in (
													select distinct os.person_id 
													from obs os
													where os.concept_id = 4155 and os.value_coded = 2146
													AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
											 )

									   ) AS TxRttClients
									  ORDER BY TxRttClients.Age)		  

					UNION

					(SELECT Id, Age, Gender, 'TX_ML_STOPPED' AS Outcome
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender

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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
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
									   WHERE 
											 -- ART TREATMENT INTERRUPTION/REFUSED OR STOPPED
											 o.person_id in (
													select distinct os.person_id 
													from obs os
													where os.concept_id = 3701 
													AND os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
											 )
									   ) AS TxMLClients)

					UNION

					(SELECT Id, Age, Gender, 'TX_ML_LFTU<3m' AS Outcome
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender

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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
											 )
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									   WHERE
											 -- INITIATED ON ART LESS THAN 3 MONTHS AGO
											 o.person_id in (
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
									   ) AS TxMLClients)
							  
					UNION

					(SELECT Id, Age, Gender, 'TX_ML_LFTU>3m' AS Outcome
					FROM
									(select patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
														   person.gender AS Gender

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
													 and oss.obs_datetime < cast('#startDate#' as DATE)
													 group by p.person_id
													 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) between 29 and 90) as Missed_Greater_Than_28Days
											 )						 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									   WHERE 
											 -- INITIATED ON ART MORE THAN 3 MONTHS AGO
											 o.person_id in (
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
									   ) AS TxMLClients)
						) AS Total_TxML
			  ) AS Totals)
) AS Total_Aggregated_TxML
ORDER BY Total_Aggregated_TxML.sort_order
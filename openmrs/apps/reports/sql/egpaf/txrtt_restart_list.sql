(SELECT distinct patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Missed>28Days_Restarted' AS 'Program_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
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
								 having datediff(CAST('#startDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 AND os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )

						 -- Transfered Out to Another Site during thier latest encounter before the start date -- REVIEW ACCORDINGLY
						 AND o.person_id not in (
								select distinct os.person_id 
								from obs os
								where os.concept_id = 4155 and os.value_coded = 2146
								-- AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								AND os.obs_datetime < CAST('#startDate#' AS DATE)								
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where (os.concept_id = 2253 AND DATE(os.value_datetime) BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
						 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE 	observed_age_group.report_group_name = 'Modified_Ages' AND
							o.person_id not in (
								select patient.patient_id
											from obs os
													-- CAME IN PREVIOUS 1 MONTH AND WAS GIVEN (2, 3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
													 INNER JOIN patient ON os.person_id = patient.patient_id
													  AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) and YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH))
													  AND patient.voided = 0 AND os.voided = 0 
													  AND (os.concept_id = 4174 and (os.value_coded = 4176 or os.value_coded = 4177 or os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247)))
								AND 
								o.person_id not in (
								select patient.patient_id
												from obs os
												-- CAME IN PREVIOUS 2 MONTHS AND WAS GIVEN (3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
												 INNER JOIN patient ON os.person_id = patient.patient_id 
													 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
													 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
													 AND patient.voided = 0 AND os.voided = 0
													 AND os.concept_id = 4174 and (os.value_coded = 4177 or os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247))

								AND
								o.person_id not in (						  
								select patient.patient_id
												from obs os
												-- CAME IN PREVIOUS 3 MONTHS AND WAS GIVEN (4, 5, 6 MONHTS SUPPLY OF DRUGS)
												 INNER JOIN patient ON os.person_id = patient.patient_id 
													 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
													 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
													 AND patient.voided = 0 AND os.voided = 0 
													 AND os.concept_id = 4174 and (os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247))

								AND
								o.person_id not in (
								select patient.patient_id

												from obs os
												-- CAME IN PREVIOUS 4 MONTHS AND WAS GIVEN (5, 6 MONHTS SUPPLY OF DRUGS)
												 INNER JOIN patient ON os.person_id = patient.patient_id 
													 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
													 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
													 AND patient.voided = 0 AND os.voided = 0 
													 AND os.concept_id = 4174 and (os.value_coded = 4246 or os.value_coded = 4247))
								AND
								o.person_id not in (
								select patient.patient_id

												from obs os
												-- CAME IN PREVIOUS 5 MONTHS AND WAS GIVEN (6 MONHTS SUPPLY OF DRUGS)
												 INNER JOIN patient ON os.person_id = patient.patient_id 
													 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
													 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
													 AND patient.voided = 0 AND os.voided = 0 
													 AND os.concept_id = 4174 and os.value_coded = 4247)
										
								AND
								o.person_id not in (
								select patient.patient_id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4175
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28			
												))
								AND
								o.person_id not in (
								select patient.patient_id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4176
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
																
												))
								AND
								o.person_id not in (
								select distinct patient.patient_id AS Id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4177
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
												))
								AND
								o.person_id not in (
								select distinct patient.patient_id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4245
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
																
												))
								AND
								o.person_id not in (
								select distinct patient.patient_id AS Id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4246
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
																
												))
								AND
								o.person_id not in (
								select distinct patient.patient_id
												from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
													 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
													 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
													 AND patient.voided = 0 AND o.voided = 0 
													 AND o.concept_id = 4174 and o.value_coded = 4247
													 AND o.person_id in (
														select distinct os.person_id from obs os
														where 
															MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
															AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH))
															AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
												))
				   ) AS TwentyEightDayDefaulters)
select distinct Patient_Identifier,
				Patient_Name, 
				Age, 
				DOB, 
				Gender, 
				age_group, 
				Program_Status,
				regimen_name, 
				encounter_date, 
				follow_up, 
				drug_duration, 
				intake_regimen, 
				ART_Start, 
				Blood_drawn, 
				Results_received, 
				VL_result, 
				Patient_received_results
from
(

		(SELECT Id, patientIdentifier as "Patient_Identifier", patientName as "Patient_Name", Age, DOB, Gender, age_group, 'Initiated' as 'Program_Status'
			FROM
						(select distinct patient.patient_id as Id,
											   patient_identifier.identifier as patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) as patientName,
											   floor(datediff(CAST('#endDate#' as DATE), person.birthdate)/365) as Age,
											   person.birthdate as DOB,
											   person.gender as Gender,
											   observed_age_group.name as age_group

						from obs o
								-- CLIENTS NEWLY INITIATED ON ART
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND (o.concept_id = 2249 

								AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
								AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
								 )
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.person_id not in (
									select distinct os.person_id from obs os
									where os.concept_id = 3634 
									AND os.value_coded = 2095 
									AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
									AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
								 )	
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Newly_Initiated_ART_Clients
		ORDER BY Newly_Initiated_ART_Clients.patientName)

		UNION

		(SELECT Id, patientIdentifier as "Patient_Identifier", patientName as "Patient_Name", Age, DOB, Gender, age_group, 'Seen' AS 'Program_Status'
		FROM (

		select distinct patient.patient_id as Id,
											   patient_identifier.identifier as patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) as patientName,
											   floor(datediff(CAST('#endDate#' as DATE), person.birthdate)/365) as Age,
											   person.birthdate as DOB,
											   person.gender as Gender,
											   observed_age_group.name as age_group
				from obs o
										-- CLIENTS SEEN FOR ART
										 INNER JOIN patient ON o.person_id = patient.patient_id
										 AND (o.concept_id = 3843 AND o.value_coded = 3841 OR o.value_coded = 3842)
										 AND MONTH(o.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
										 AND YEAR(o.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
										 AND patient.voided = 0 AND o.voided = 0
										 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
										 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
										 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'

		) AS Clients_Seen

		WHERE Clients_Seen.Id not in (
				select distinct patient.patient_id AS Id
				from obs o
						-- CLIENTS NEWLY INITIATED ON ART
						 INNER JOIN patient ON o.person_id = patient.patient_id
						 AND (o.concept_id = 2249 
													AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
													AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
								)		
						 AND patient.voided = 0 AND o.voided = 0

									)
		AND Clients_Seen.Id not in (
									select distinct(o.person_id)
									from obs o
									where o.person_id in (
											-- FOLLOW UPS
												select firstquery.person_id
												from
												(
												select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
												from obs oss
															where oss.voided=0 
															and oss.concept_id=3752 
															and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
															and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
															group by oss.person_id) firstquery
												inner join (
															select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
															from obs os
															where concept_id = 3752
															and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
															group by os.person_id
															having last_ap < 0
												) secondquery
												on firstquery.person_id = secondquery.person_id
									) and o.person_id in (
											-- TOUTS
											select distinct(person_id)
											from
											(
												select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
												from obs os
												where os.concept_id=2266
												group by os.person_id
												having latest_transferout <= CAST('#endDate#' AS DATE)
											) as TOUTS
									)					
				)

		AND Clients_Seen.Id not in 
							(
								select distinct(o.person_id)
								from obs o
								where o.person_id in (
										-- FOLLOW UPS
													select firstquery.person_id
													from
													(
													select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
													from obs oss
																where oss.voided=0 
																and oss.concept_id=3752 
																and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
																and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
																group by oss.person_id) firstquery
													inner join (
																select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
																from obs os
																where concept_id = 3752
																and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
																group by os.person_id
																having last_ap < 0
													) secondquery
													on firstquery.person_id = secondquery.person_id
								)
								and o.person_id in (
										-- Death
													select distinct p.person_id
													from person p
													where dead = 1
													and death_date <= CAST('#endDate#' AS DATE)		
								)
							)

		ORDER BY Clients_Seen.patientName)

		UNION

		-- INCLUDE MISSED APPOINTMENTS WITHIN 28 DAYS ACCORDING TO THE NEW PEPFAR GUIDELINE
		(SELECT Id, patientIdentifier as "Patient_Identifier", patientName as "Patient_Name", Age, DOB, Gender, age_group, 'MissedWithin28Days' AS 'Program_Status'
		FROM
						(select distinct patient.patient_id as Id,
											   patient_identifier.identifier as patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) as patientName,
											   floor(datediff(CAST('#endDate#' as DATE), person.birthdate)/365) as Age,
											   person.birthdate as DOB,
											   person.gender as Gender,
											   observed_age_group.name as age_group

						from obs o
								-- PATIENTS WHO HAVE NOT RECEIVED ARV's WITHIN 4 WEEKS (i.e. 28 days) OF THIER LAST MISSED DRUG PICK-UP
								 inner join patient on o.person_id = patient.patient_id
								 and patient.voided = 0 AND o.voided = 0
								 and o.concept_id = 3752
								 and o.obs_id in (
										select os.obs_id
										from obs os
										where os.concept_id=3752
										and os.obs_id in (
											select observation_id
											from
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss 
													inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
													and oss.value_datetime <= cast('#endDate#' as date)
												group by p.person_id) as latest_followup_obs
										)
										and os.value_datetime < cast('#endDate#' as date)
										and datediff(cast('#endDate#' as date), os.value_datetime) between 0 and 28
								 )
								 
						and o.person_id not in (
									select distinct os.person_id
									from obs os
									where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
									AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
									AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)
									
						and o.person_id not in (
									select distinct person_id
									from obs 
									where concept_id = 2249
									AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
									AND YEAR(obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)

						and o.person_id not in (
									select distinct(o.person_id)
									from obs o
									where o.person_id in (
									-- TOUTS
											select distinct person_id
													from
													(
														select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
														from obs os
														where os.concept_id=2266
														group by os.person_id
														having latest_transferout <= CAST('#endDate#' AS DATE)
													) as TOUTS
												
													 where TOUTS.person_id not in
														 (
															 select oss.person_id
															 from obs oss
															 where concept_id = 3843
															 and CAST(oss.obs_datetime AS DATE) > latest_transferout
															 and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														 )
								   
												)
									and o.person_id not in(
												select distinct os.person_id
												from obs os
												where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
												AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
												AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)
												)					

								 and o.person_id not in (
											select person_id 
											from person 
											where death_date <= cast('#endDate#' as date)
											and dead = 1
								 )
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1						 
								 INNER JOIN reporting_age_group AS observed_age_group ON
								 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE 	observed_age_group.report_group_name = 'Modified_Ages'

						   AND o.person_id in (
											select distinct (person_id)									
											from 			
												(select os.person_id, cast(max(os.value_datetime) as date) as latest_appointment
														from obs os
														where os.concept_id=3752 
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id		
												) as app
												where latest_appointment < CAST('#endDate#' AS DATE)
												and DATEDIFF(CAST('#endDate#' AS DATE),latest_appointment) BETWEEN 0 AND 28



						   )			
						   ) AS TwentyEightDayDefaulters
						   order by TwentyEightDayDefaulters.patientName
		)
						   
		UNION

		(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, DOB, Gender, age_group, 'Seen_Prev_Months' AS 'Program_Status'
		FROM (
		(select distinct patient.patient_id as Id,
											   patient_identifier.identifier as patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) as patientName,
											   floor(datediff(CAST('#endDate#' as DATE), person.birthdate)/365) as Age,
											   person.birthdate as DOB,
											   person.gender as Gender,
											   observed_age_group.name as age_group

				from obs o
						-- CAME IN PREVIOUS 1 MONTH AND WAS GIVEN (2, 3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						  AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) and YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) AND patient.voided = 0 AND o.voided = 0 
						  AND (o.concept_id = 4174 and o.value_coded in (4175,4176, 4177, 4245,4246,4247,4820))
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
				   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 2 MONTHS AND WAS GIVEN (3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded in (4176, 4177, 4245,4246,4247,4820)
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
			   
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 3 MONTHS AND WAS GIVEN (4, 5, 6 MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded in ( 4177, 4245,4246,4247,4820)
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0			 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 4 MONTHS AND WAS GIVEN (5, 6 MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded in ( 4245,4246,4247,4820)
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 5 MONTHS AND WAS GIVEN (6 MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded in (4246,4247,4820)
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 6 MONTHS AND WAS GIVEN (6+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded in (4247,4820)
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 7 MONTHS AND WAS GIVEN (7+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 8 MONTHS AND WAS GIVEN (7+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group										   

						from obs o
						-- CAME IN PREVIOUS 9 MONTHS AND WAS GIVEN (7+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 10 MONTHS AND WAS GIVEN (7+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						-- CAME IN PREVIOUS 11 MONTHS AND WAS GIVEN (7+ MONHTS SUPPLY OF DRUGS)
						 INNER JOIN patient ON o.person_id = patient.patient_id 
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
				

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))


		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
										
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
				   
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
										
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
				   
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
										
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

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
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))	   

		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
	 
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -8 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
		 
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -9 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))  
		 
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -10 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
		 
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -11 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))                                                                                              	
		
		UNION

		(select distinct patient.patient_id AS Id,
										   patient_identifier.identifier AS patientIdentifier,
										   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
										   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
										   person.birthdate as DOB,
										   person.gender as Gender,
										   observed_age_group.name as age_group

						from obs o
						 INNER JOIN patient ON o.person_id = patient.patient_id
							 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) 
							 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) 
							 AND patient.voided = 0 AND o.voided = 0 
							 AND o.concept_id = 4174 and o.value_coded = 4820
							 AND o.person_id in (
								select distinct os.person_id from obs os
								where 
									MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) 
									AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH))
									AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
							 )
							 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
							 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
							 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
							 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
				   WHERE observed_age_group.report_group_name = 'Modified_Ages'	
						   and o.person_id not in (
								select distinct(person_id)
								from
										(
										select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
														from obs os
														where os.concept_id=3843
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
								AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								and latest_visit > CAST(o.obs_datetime AS DATE) 
								and latest_visit <= CAST('#endDate#' AS DATE)
							))
				   
		) AS ARTCurrent_PrevMonths
		 
		WHERE ARTCurrent_PrevMonths.Id not in (
						SELECT os.person_id 
						FROM obs os
						WHERE (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
						AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
												)
		and ARTCurrent_PrevMonths.Id not in (
					   select distinct patient.patient_id AS Id
					   from obs oss
								   -- CLIENTS NEWLY INITIATED ON ART
						INNER JOIN patient ON oss.person_id = patient.patient_id													
						AND (oss.concept_id = 2249 
						AND MONTH(oss.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(oss.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						)
						AND patient.voided = 0 AND oss.voided = 0)
		AND ARTCurrent_PrevMonths.Id not in (
											select distinct(o.person_id)
											from obs o
											where o.person_id in (
													-- FOLLOW UPS
														select firstquery.person_id
														from
														(
														select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, max(oss.value_datetime) as latest_followup_obs
														from obs oss
																	where oss.voided=0 
																	and oss.concept_id=3752 
																	and oss.obs_datetime <= CAST('#endDate#' AS DATE)
																	and oss.obs_datetime > DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
																	group by oss.person_id) firstquery
														inner join (
																	select os.person_id,datediff(max(os.value_datetime), CAST('#endDate#' AS DATE)) as last_ap
																	from obs os
																	where concept_id = 3752
																	and os.obs_datetime <= CAST('#endDate#' AS DATE)
																	group by os.person_id
																	having last_ap < 0
														) secondquery
														on firstquery.person_id = secondquery.person_id
											) and o.person_id in (
													-- TOUTS
													select distinct(person_id)
													from
													(
														select os.person_id, max(os.value_datetime) as latest_transferout
														from obs os
														where os.concept_id=2266
														group by os.person_id
														having latest_transferout <= CAST('#endDate#' AS DATE)
													) as TOUTS
											)
				)
		AND ARTCurrent_PrevMonths.Id not in (
								-- Death
											select distinct p.person_id
											from person p
											where dead = 1
											and death_date <= CAST('#endDate#' AS DATE)		
												)

		 and ARTCurrent_PrevMonths.Id not in ( -- cater for clients due for appointments who may move to missed
								select distinct(o.person_id)
								from obs o
								inner JOIN
										(
										select os.person_id, cast(max(os.value_datetime) as date) as latest_appointment
														from obs os
														where os.concept_id=3752
														and os.obs_datetime <= CAST('#endDate#' AS DATE)
														group by os.person_id
														
										) as visit ON o.person_id  = visit.person_id
								where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH) 
								and latest_appointment < CAST('#endDate#' AS DATE)
							)                                       
		order by ARTCurrent_PrevMonths.patientName)

) as txcurr left outer join (
		-- regimen
		select a.person_id, 
		case 
		when a.value_coded = 2201 then '1c'
		when a.value_coded = 2202 then '4c'
		when a.value_coded = 2203 then '1d'
		when a.value_coded = 2204 then '4d'
		when a.value_coded = 2205 then '1e'
		when a.value_coded = 2207 then '1f'
		when a.value_coded = 2209 then '2d'
		when a.value_coded = 2210 then '2c'
		when a.value_coded = 3672 then '1g'
		when a.value_coded = 3673 then '1h'
		when a.value_coded = 3676 then '2g'
		when a.value_coded = 3678 then '2i'
		when a.value_coded = 3679 then '4e'
		when a.value_coded = 3680 then '4f'
		when a.value_coded = 3681 then '5a'
		when a.value_coded = 3682 then '5b'
		when a.value_coded = 2143 then 'Other'
		when a.value_coded = 4678 THEN "1j"
		when a.value_coded = 4679 THEN "1k"
		when a.value_coded = 4680 THEN "1m"
		when a.value_coded = 4681 THEN "1n"
		when a.value_coded = 4682 THEN "1p"
		when a.value_coded = 4683 THEN "1q"
		when a.value_coded = 4684 THEN "4g"
		when a.value_coded = 4685 THEN "4h"
		when a.value_coded = 4686 THEN "4i"
		when a.value_coded = 4687 THEN "4j"
		when a.value_coded = 4688 THEN "4k"
		when a.value_coded = 4689 THEN "2j"
		when a.value_coded = 4690 THEN "2k"
		when a.value_coded = 4691 THEN "2l"
		when a.value_coded = 4692 THEN "2m"
		when a.value_coded = 4693 THEN "2n"
		when a.value_coded = 4694 THEN "2o"
		when a.value_coded = 4695 THEN "2p"
		when a.value_coded = 4696 THEN "5c"
		when a.value_coded = 4697 THEN "5d"
		when a.value_coded = 4698 THEN "5e"
		when a.value_coded = 4699 THEN "5f"
		when a.value_coded = 4700 THEN "5g"
		when a.value_coded = 4701 THEN "5h"
		when a.value_coded = 4702 THEN "6c"
		when a.value_coded = 4703 THEN "6d"
		when a.value_coded = 4704 THEN "6e"
		when a.value_coded = 4705 THEN "4f"
		when a.value_coded = 4706 THEN "3d"
		when a.value_coded = 4707 THEN "3e"
		when a.value_coded = 4708 THEN "3f"
		when a.value_coded = 4709 THEN "3g"
		when a.value_coded = 4710 THEN "3h"
		else 'NewRegimen' end as regimen_name
		from obs a
		inner join 
				(select o.person_id,max(obs_datetime) maxdate 
				from obs o 
				where obs_datetime <= '#endDate#'
				and o.concept_id = 2250
				group by o.person_id 
				)latest 
				on latest.person_id = a.person_id
		where a.concept_id = 2250 
		and  a.obs_datetime = maxdate
		

) as regimen ON txcurr.Id = regimen.person_id

left outer join
-- encounter date
(select o.person_id,CAST(maxdate AS DATE) as encounter_date,CAST(value_datetime AS DATE) as follow_up
from obs o 
inner join 
		(select person_id,max(obs_datetime) maxdate 
		from obs a
		where obs_datetime <= '#endDate#'
		and concept_id = 3752 and voided=0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 3752
	and  o.obs_datetime = maxdate and voided=0
	)encounter
ON txcurr.Id = encounter.person_id

left outer join
-- drug supply
(select o.person_id,
		case
			 when value_coded = 4243 then "2 weeks"
			 when value_coded = 4175 then "1 Month"
			 when value_coded = 4176 then "2 Months"
			 when value_coded = 4177 then "3 Months"
			 when value_coded = 4245 then "4 Months"
			 when value_coded = 4246 then "5 Months"
			 when value_coded = 4247 then "6 Months"
			 when value_coded = 4820 then "7 Months"
			 else "other" 
		end AS drug_duration,
		maxdate
from obs o inner join 
		(select a.person_id,max(obs_datetime) maxdate
		 from obs a
		 where obs_datetime <= '#endDate#' and concept_id = 4174 and a.voided=0
		 group by a.person_id 
		) as latest on latest.person_id = o.person_id
		where concept_id = 4174 and o.obs_datetime = maxdate and o.voided=0
) duration ON txcurr.Id = duration.person_id

left outer join
-- intake regimen
(
select a.person_id,case 
when a.value_coded = 2201 then '1c'
when a.value_coded = 2202 then '4c'
when a.value_coded = 2203 then '1d'
when a.value_coded = 2204 then '4d'
when a.value_coded = 2205 then '1e'
when a.value_coded = 2207 then '1f'
when a.value_coded = 2209 then '2d'
when a.value_coded = 2210 then '2c'
when a.value_coded = 3672 then '1g'
when a.value_coded = 3673 then '1h'
when a.value_coded = 3676 then '2g'
when a.value_coded = 3678 then '2i'
when a.value_coded = 3679 then '4e'
when a.value_coded = 3680 then '4f'
when a.value_coded = 3681 then '5a'
when a.value_coded = 3682 then '5b'
when a.value_coded = 2143 then 'Other'
when a.value_coded = 4678 THEN "1j"
when a.value_coded = 4679 THEN "1k"
when a.value_coded = 4680 THEN "1m"
when a.value_coded = 4681 THEN "1n"
when a.value_coded = 4682 THEN "1p"
when a.value_coded = 4683 THEN "1q"
when a.value_coded = 4684 THEN "4g"
when a.value_coded = 4685 THEN "4h"
when a.value_coded = 4686 THEN "4i"
when a.value_coded = 4687 THEN "4j"
when a.value_coded = 4688 THEN "4k"
when a.value_coded = 4689 THEN "2j"
when a.value_coded = 4690 THEN "2k"
when a.value_coded = 4691 THEN "2l"
when a.value_coded = 4692 THEN "2m"
when a.value_coded = 4693 THEN "2n"
when a.value_coded = 4694 THEN "2o"
when a.value_coded = 4695 THEN "2p"
when a.value_coded = 4696 THEN "5c"
when a.value_coded = 4697 THEN "5d"
when a.value_coded = 4698 THEN "5e" 
when a.value_coded = 4699 THEN "5f"
when a.value_coded = 4700 THEN "5g"
when a.value_coded = 4701 THEN "5h"
when a.value_coded = 4702 THEN "6c"
when a.value_coded = 4703 THEN "6d"
when a.value_coded = 4704 THEN "6e"
when a.value_coded = 4705 THEN "4f"
when a.value_coded = 4706 THEN "3d"
when a.value_coded = 4707 THEN "3e"
when a.value_coded = 4708 THEN "3f"
when a.value_coded = 4709 THEN "3g"
when a.value_coded = 4710 THEN "3h"
else 'New Regimen' end as intake_regimen
	from obs a,obs b
	where a.person_id = b.person_id
	and a.concept_id = 2250 and a.voided=0
	and b.concept_id = 2397
	and a.obs_datetime = b.obs_datetime
	) intakes ON txcurr.Id = intakes.person_id
	
-- ART START
	left outer join
	(
		select person_id,CAST(value_datetime AS DATE) as ART_Start
		from obs where concept_id = 2249 and voided=0
	) as intake_date on txcurr.Id = intake_date.person_id

-- date blood drawn
	left outer join
	(select o.person_id,CAST(value_datetime AS DATE) as Blood_drawn
	from obs o inner join 
		(select person_id,max(obs_datetime) maxdate 
		 from obs a
		 where obs_datetime <= '#endDate#' and concept_id = 4267 and a.voided=0
		 group by person_id 
		) as latest on latest.person_id = o.person_id
	where concept_id = 4267 and  o.obs_datetime = maxdate	
	) as blood_draw
ON txcurr.Id = blood_draw.person_id

-- date results received
left outer join
(select o.person_id,CAST(value_datetime AS DATE) as Results_received
from obs o 
inner join 
		(select person_id,max(obs_datetime) maxdate 
		from obs a
		where obs_datetime <= '#endDate#'
		and concept_id = 4268 and a.voided=0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4268
	and  o.obs_datetime = maxdate	
	)results_rece
ON txcurr.Id = results_rece.person_id

-- results
left outer join
(select o.person_id,case 
 when value_coded = 4263 then "Undetectale"
 when value_coded = 4264 then "less than 20"
 when value_coded = 4265 then "Greater or equal to 20"
else "other" 
end AS VL_result
from obs o
inner join 
		(select person_id,max(obs_datetime) maxdate 
		from obs a
		where obs_datetime <= '#endDate#'
		and concept_id = 4266 and a.voided=0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4266
	and  o.obs_datetime = maxdate	
	)results
ON txcurr.Id = results.person_id

-- date results given to patient
left outer join
(select o.person_id,CAST(value_datetime AS DATE) as Patient_received_results
from obs o 
inner join 
		(select person_id,max(obs_datetime) maxdate 
		from obs a
		where obs_datetime <= '#endDate#'
		and concept_id = 4274 and a.voided=0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4274
	and  o.obs_datetime = maxdate	
	)patients
ON txcurr.Id = patients.person_id

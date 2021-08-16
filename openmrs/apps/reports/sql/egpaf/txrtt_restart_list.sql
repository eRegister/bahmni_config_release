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
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
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
				   -- MMD
								select osm.person_id
								from obs osm
								INNER JOIN patient ON osm.person_id = patient.patient_id
								AND osm.person_id in (
										select active_clients.person_id
										from
										(select B.person_id, B.obs_group_id, B.value_datetime AS latest_follow_up
											from obs B
											inner join 
											(select person_id, max(obs_datetime), SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
											from obs where concept_id = 3753
											and obs_datetime <= cast('#endDate#' as date)
											group by person_id) as A
											on A.observation_id = B.obs_group_id
											where concept_id = 3752
											and A.observation_id = B.obs_group_id	
										) as active_clients
										where active_clients.latest_follow_up >= cast('#endDate#' as date)
											and active_clients.person_id not in (
																select distinct os.person_id
																from obs os
																where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
																AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
																AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
																)
															
											and active_clients.person_id not in (
																select distinct os.person_id
																from obs os
																where concept_id = 2249
																AND MONTH(os.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
																AND YEAR(os.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
																)

											and active_clients.person_id not in (
																select distinct(os.person_id)
																from obs os
																where os.person_id in (
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
																and os.person_id in (
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
											and active_clients.person_id not in (
																		select person_id 
																		from person 
																		where death_date <= cast('#endDate#' as date)
																		and dead = 1
											)
						   )
				   

				   
				   
				   )) AS TwentyEightDayDefaulters)
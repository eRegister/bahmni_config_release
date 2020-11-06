select distinct Patient_Identifier,ART_Unique_Number,Patient_Name,Gender,DOB,Age,age_group,Program_Status,
ART_Start,Intake_regimen,Encounter_date,Follow_up,Current_regimen,Drug_duration,Blood_drawn,Results_received,VL_result,Patient_received_results,TB_status
from obs o
left outer join

(
	(SELECT Id,patientIdentifier AS "Patient_Identifier",UniqueNumber AS "ART_Unique_Number", patientName AS "Patient_Name",Gender, DOB, Age, age_group, 'Initiated' AS 'Program_Status',sort_order
	FROM
                (select distinct patient.patient_id AS Id,
									   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.birthdate DOB,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order
									  

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
						 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
						 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
						 
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'HIV_ages') AS Newly_Initiated_ART_Clients
ORDER BY Newly_Initiated_ART_Clients.Age)

UNION

(SELECT Id,patientIdentifier AS "Patient_Identifier",UniqueNumber AS "ART_Unique_Number", patientName AS "Patient_Name",Gender, DOB, Age, age_group, 'Seen' AS 'Program_Status',sort_order
FROM (

select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
								   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order
								  
        from obs o
								-- CLIENTS SEEN FOR ART
                                INNER JOIN patient ON o.person_id = patient.patient_id
                                 AND (o.concept_id = 3843 AND o.value_coded = 3841 OR o.value_coded = 3842)
								 AND MONTH(o.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
								 AND YEAR(o.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
                                 AND patient.voided = 0 AND o.voided = 0
                                 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
                                 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
                                 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
								 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
								 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'HIV_ages'

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
													and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
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
														and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
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

ORDER BY Clients_Seen.Age)

UNION

(SELECT Id,patientIdentifier AS "Patient Identifier",UniqueNumber AS "ART_Unique_Number", patientName AS "Patient Name", Gender, DOB, Age, age_group,'Seen_Prev_Months' AS 'Program_Status',sort_order
FROM (
(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

        from obs o
				-- CAME IN PREVIOUS 1 MONTH AND WAS GIVEN (2, 3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
				  AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) and YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) AND patient.voided = 0 AND o.voided = 0 
				  AND (o.concept_id = 4174 and (o.value_coded = 4176 or o.value_coded = 4177 or o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247))
                 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
				 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
				 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
				 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))

UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 2 MONTHS AND WAS GIVEN (3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4177 or o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
	   
UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 3 MONTHS AND WAS GIVEN (4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0			 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))

UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 4 MONTHS AND WAS GIVEN (5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 5 MONTHS AND WAS GIVEN (6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4247
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		

UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))


UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		   
UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		   
UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   pid.identifier AS patientIdentifier,
									   pat.identifier AS UniqueNumber,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

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
					 INNER JOIN patient_identifier pid ON pid.patient_id = person.person_id and pid.identifier_type = 3 AND pid.preferred=1 AND pid.voided = 0
					 INNER JOIN patient_identifier pat ON pid.patient_id = pat.patient_id and pat.identifier_type = 5 AND pat.voided = 0
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
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
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
															and oss.obs_datetime > DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
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
order by 3
)
) previous
ON o.person_id = Id


left outer join
(
-- regimen
select a.person_id, 
case 
when a.value_coded = 2201 then "1c"
when a.value_coded = 2203 then "1d"
when a.value_coded = 2205 then "1e"
when a.value_coded = 2207 then "1f"
when a.value_coded = 3672 then "1g"
when a.value_coded = 3673 then "1h"
when a.value_coded = 4678 THEN "1j"
when a.value_coded = 4679 THEN "1k"
when a.value_coded = 4680 THEN "1m"
when a.value_coded = 4681 THEN "1n"
when a.value_coded = 4682 THEN "1p"
when a.value_coded = 4683 THEN "1q"
when a.value_coded = 2210 then "2c"
when a.value_coded = 2209 then "2d"
when a.value_coded = 3674 then "2e"
when a.value_coded = 3675 then "2f"
when a.value_coded = 3676 then "2g"
when a.value_coded = 3677 then "2h"
when a.value_coded = 3678 then "2q"
when a.value_coded = 4689 THEN "2j"
when a.value_coded = 4690 THEN "2k"
when a.value_coded = 4691 THEN "2l"
when a.value_coded = 4692 THEN "2m"
when a.value_coded = 4693 THEN "2n"
when a.value_coded = 4694 THEN "2o"
when a.value_coded = 4695 THEN "2p"
when a.value_coded = 3683 THEN "3a"
when a.value_coded = 3684 THEN "3b"
when a.value_coded = 3685 THEN "3c"
when a.value_coded = 4706 THEN "3d"
when a.value_coded = 4707 THEN "3e"
when a.value_coded = 4708 THEN "3f"
when a.value_coded = 4709 THEN "3g"
when a.value_coded = 4710 THEN "3h"
when a.value_coded = 2202 then "4c"
when a.value_coded = 2204 then "4d"
when a.value_coded = 3679 then "4e"
when a.value_coded = 3680 then "4f"
when a.value_coded = 4684 THEN "4g"
when a.value_coded = 4685 THEN "4h"
when a.value_coded = 4686 THEN "4L"
when a.value_coded = 4687 THEN "4j"
when a.value_coded = 4688 THEN "4k"
when a.value_coded = 2143 then "Other"
when a.value_coded = 3681 then "5a"
when a.value_coded = 3682 then "5b"
when a.value_coded = 4696 THEN "5c"
when a.value_coded = 4697 THEN "5d"
when a.value_coded = 4698 THEN "5e"
when a.value_coded = 4699 THEN "5f"
when a.value_coded = 4700 THEN "5g"
when a.value_coded = 4701 THEN "5h"
when a.value_coded = 3686 THEN "6a"
when a.value_coded = 3687 THEN "6b"
when a.value_coded = 4702 THEN "6c"
when a.value_coded = 4703 THEN "6d"
when a.value_coded = 4704 THEN "6e"
when a.value_coded = 4705 THEN "6f"
else 'NewRegimen' end as Current_regimen
from obs a
inner join 
		(select o.person_id,cast(max(o.obs_datetime) as date) maxdate 
		from obs o,obs b 
		where o.person_id = b.person_id
        AND cast(o.obs_datetime as date) <= cast('#endDate#' as date)
		and o.concept_id = 2250
        and b.concept_id = 2397
		and o.voided = 0
        and b.voided = 0
        and CAST(o.obs_datetime AS DATE) = CAST(b.obs_datetime AS DATE)
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
		inner join obs b on a.person_id = b.person_id
where a.concept_id = 2250 
and b.concept_id = 2397
and a.voided = 0
and b.voided = 0
and  cast(a.obs_datetime as date) = maxdate
and CAST(a.obs_datetime AS DATE) = CAST(b.obs_datetime AS DATE)
) regimen

ON previous.Id = regimen.person_id

left outer JOIN
-- encounter date
(select o.person_id,CAST(maxdate AS DATE) as Encounter_date,CAST(value_datetime AS DATE) as Follow_up
from obs o 
inner join 
		(select person_id,CAST(max(obs_datetime) AS DATE) maxdate 
		from obs a
		where CAST(obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 3752
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 3752
	and o.voided = 0
	and  CAST(o.obs_datetime AS DATE) = maxdate	
	)encounter
ON previous.Id = encounter.person_id

left outer JOIN
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
else "other" 
end AS Drug_duration,maxdate
from obs o
inner join 
		(select a.person_id,CAST(max(obs_datetime) AS DATE) maxdate 
		from obs a
		where CAST(obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 4174
		and a.voided = 0
		group by a.person_id 
		)latest 
		on latest.person_id = o.person_id
where concept_id = 4174
and o.voided = 0
and  CAST(o.obs_datetime AS DATE) = maxdate
) duration
ON previous.Id = duration.person_id

left outer JOIN
-- intake regimen
(
select a.person_id,case 
when a.value_coded = 2201 then "1c"
when a.value_coded = 2203 then "1d"
when a.value_coded = 2205 then "1e"
when a.value_coded = 2207 then "1f"
when a.value_coded = 3672 then "1g"
when a.value_coded = 3673 then "1h"
when a.value_coded = 4678 THEN "1j"
when a.value_coded = 4679 THEN "1k"
when a.value_coded = 4680 THEN "1m"
when a.value_coded = 4681 THEN "1n"
when a.value_coded = 4682 THEN "1p"
when a.value_coded = 4683 THEN "1q"
when a.value_coded = 2210 then "2c"
when a.value_coded = 2209 then "2d"
when a.value_coded = 3674 then "2e"
when a.value_coded = 3675 then "2f"
when a.value_coded = 3676 then "2g"
when a.value_coded = 3677 then "2h"
when a.value_coded = 3678 then "2q"
when a.value_coded = 4689 THEN "2j"
when a.value_coded = 4690 THEN "2k"
when a.value_coded = 4691 THEN "2l"
when a.value_coded = 4692 THEN "2m"
when a.value_coded = 4693 THEN "2n"
when a.value_coded = 4694 THEN "2o"
when a.value_coded = 4695 THEN "2p"
when a.value_coded = 3683 THEN "3a"
when a.value_coded = 3684 THEN "3b"
when a.value_coded = 3685 THEN "3c"
when a.value_coded = 4706 THEN "3d"
when a.value_coded = 4707 THEN "3e"
when a.value_coded = 4708 THEN "3f"
when a.value_coded = 4709 THEN "3g"
when a.value_coded = 4710 THEN "3h"
when a.value_coded = 2202 then "4c"
when a.value_coded = 2204 then "4d"
when a.value_coded = 3679 then "4e"
when a.value_coded = 3680 then "4f"
when a.value_coded = 4684 THEN "4g"
when a.value_coded = 4685 THEN "4h"
when a.value_coded = 4686 THEN "4L"
when a.value_coded = 4687 THEN "4j"
when a.value_coded = 4688 THEN "4k"
when a.value_coded = 2143 then "Other"
when a.value_coded = 3681 then "5a"
when a.value_coded = 3682 then "5b"
when a.value_coded = 4696 THEN "5c"
when a.value_coded = 4697 THEN "5d"
when a.value_coded = 4698 THEN "5e"
when a.value_coded = 4699 THEN "5f"
when a.value_coded = 4700 THEN "5g"
when a.value_coded = 4701 THEN "5h"
when a.value_coded = 3686 THEN "6a"
when a.value_coded = 3687 THEN "6b"
when a.value_coded = 4702 THEN "6c"
when a.value_coded = 4703 THEN "6d"
when a.value_coded = 4704 THEN "6e"
when a.value_coded = 4705 THEN "6f"
else 'New Regimen' end as Intake_regimen
	from obs a,obs b
	where a.person_id = b.person_id
	and a.concept_id = 2250
	and b.concept_id = 2397
	and a.voided = 0
	and b.voided = 0
	and CAST(a.obs_datetime AS DATE) = CAST(b.obs_datetime AS DATE)
	) intakes
	ON previous.Id = intakes.person_id
	
-- ART START	
	left outer join
	(
	select o.person_id,CAST(value_datetime AS DATE) as ART_start
	from obs o 
	inner join 
		(select person_id,CAST(max(obs_datetime) AS DATE) maxdate 
		from obs a
		where CAST(obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 2249
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 2249
	and o.voided = 0
	and  CAST(o.obs_datetime AS DATE) = maxdate	
	)intake_date
	on previous.Id = intake_date.person_id

-- date blood drawn
	left outer join
	(select o.person_id,CAST(value_datetime AS DATE) as Blood_drawn
	from obs o 
	inner join 
		(select person_id,CAST(max(value_datetime) AS DATE) maxdate 
		from obs a
		where CAST(value_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 4267
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4267
	and o.voided = 0
	and  CAST(o.value_datetime AS DATE) = maxdate	
	)blood
ON previous.Id = blood.person_id

-- date results received
left outer join
(select o.person_id,CAST(value_datetime AS DATE) as Results_received
from obs o 
inner join 
		(select person_id,CAST(max(value_datetime) AS DATE) maxdate 
		from obs a
		where CAST(value_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 4268
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4268
	and o.voided = 0
	and  CAST(o.value_datetime AS DATE) = maxdate	
	)results_rece
ON previous.Id = results_rece.person_id

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
		(select person_id,CAST(max(obs_datetime) AS DATE) maxdate 
		from obs a
		where CAST(obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 4266
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4266
	and o.voided = 0
	and  CAST(o.obs_datetime AS DATE) = maxdate	
	)results
ON previous.Id = results.person_id

-- date results given to patient
left outer join
(select o.person_id,CAST(value_datetime AS DATE) as Patient_received_results
from obs o 
inner join 
		(select person_id,CAST(max(value_datetime) AS DATE) maxdate 
		from obs a
		where CAST(value_datetime AS DATE) <= CAST('#endDate#' AS DATE)
		and concept_id = 4274
		and a.voided = 0
		group by person_id 
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4274
	and o.voided = 0
	and  CAST(o.value_datetime AS DATE) = maxdate	
	)patients
ON previous.Id = patients.person_id

-- TB status
left outer join
(select o.person_id,case 
 when o.value_coded = 3709 then "No signs"
 when o.value_coded = 1876 then "suspected"
 when o.value_coded = 3639 then "On TB treatment"
else "other" 
end AS TB_status
from obs o
inner join 
		(select o.person_id,cast(max(o.obs_datetime) as date) maxdate 
		from obs o,obs b 
		where o.person_id = b.person_id
        AND cast(o.obs_datetime as date) <= cast('#endDate#' as date)
		and o.concept_id = 3710
        and b.concept_id = 3753
		and o.voided = 0
        and b.voided = 0
        and CAST(o.obs_datetime AS DATE) = CAST(b.obs_datetime AS DATE)
		group by o.person_id 
		)latest 
		on latest.person_id = o.person_id
		inner join obs b on o.person_id = b.person_id
where o.concept_id = 3710 
and b.concept_id = 3753
and o.voided = 0
and b.voided = 0
and  cast(o.obs_datetime as date) = maxdate
and CAST(o.obs_datetime AS DATE) = CAST(b.obs_datetime AS DATE)
) tb

ON previous.Id = tb.person_id
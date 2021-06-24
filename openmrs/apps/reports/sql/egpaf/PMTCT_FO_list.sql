
(SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Infected' AS 'Outcome'
							 
	FROM

			(select distinct patient.patient_id AS Id,
							patient_identifier.identifier AS patientIdentifier,
							concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
							floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
							
							person.gender AS Gender,
							observed_age_group.name AS age_group,
							observed_age_group.sort_order AS sort_order

			from obs o
					-- HIV EXPOSED INFANTS
						INNER JOIN patient ON o.person_id = patient.patient_id 
						AND o.concept_id =4558
						AND patient.voided = 0 AND o.voided = 0
						AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						AND o.person_id in (
							-- Infants between the 18 and 24 months
						select distinct os.person_id 
						from obs os
						where os.concept_id=4587 and os.value_numeric BETWEEN 18 and 24
						AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						AND patient.voided = 0 AND os.voided = 0
						)
					-- Infants infected with HIV
						AND o.person_id in (
						select distinct os.person_id 
						from obs os
						where os.concept_id = 4605 and os.value_coded in (4606,4607,4608)
						AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						AND patient.voided = 0 AND os.voided = 0
						)
			
						INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
					WHERE observed_age_group.report_group_name = 'Modified_Ages'
			) AS HTSClients_HIV_STATUS
	ORDER BY HTSClients_HIV_STATUS.Age)


UNION

(	SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Uninfected' AS 'Outcome'
							 
					FROM
					
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										    -- HIV Exposed Infants
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =4558
											 AND patient.voided = 0 AND o.voided = 0
											 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)

											 -- Infants between the 18 and 24 months
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4587 and os.value_numeric BETWEEN 18 and 24
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
												-- Infants NOT infected with HIV
                                             AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4605 and os.value_coded in (4609,4610,4611)
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
									
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
										
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)
 UNION
   
   (	SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Final Status Unknown' AS 'Outcome'
							 
					FROM
					
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										    -- HIV Exposed Infants
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =4558
											 AND patient.voided = 0 AND o.voided = 0
											 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)

											 -- Infants between the 18 and 24 months
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4587 and os.value_numeric BETWEEN 18 and 24
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
												-- Infants NOT infected with HIV
                                             AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4605 and os.value_coded =4612
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
									
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
									
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)

UNION

	   (SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'Died Without Status Known' AS 'Outcome'
							 
					FROM
					
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										    -- HIV Exposed Infants
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =4558
											 AND patient.voided = 0 AND o.voided = 0
											 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)

											 -- Infants between the 18 and 24 months
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4587 and os.value_numeric BETWEEN 18 and 24
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
												-- Infants Dead with Unknown HIV status
                                             AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4605 and os.value_coded =3650
												AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
												AND patient.voided = 0 AND os.voided = 0
											 )
									
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
									
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)

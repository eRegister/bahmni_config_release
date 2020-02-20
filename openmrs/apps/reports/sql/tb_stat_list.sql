
   (SELECT  patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												--	(select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											
											 AND patient.voided = 0 AND o.voided = 0

											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 3785 and os.value_coded in (1034,1084)
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 AND o.person_id in (
												select distinct os.person_id
												from obs os
												where os.concept_id =4666 and os.value_coded = 4323
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
)

UNION

(SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender , age_group
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												--(select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											
											 AND patient.voided = 0 AND o.voided = 0

											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 3785 and os.value_coded in (1034,1084)
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 AND o.person_id in (
												select distinct os.person_id
												from obs os
												where os.concept_id =4666 and os.value_coded = 4664
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status)
									   
									 

									   UNION

									   (
		SELECT  patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group
							
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST(' #endDate#' AS DATE), person.birthdate)/365) AS Age,
														  -- (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
									
											 AND patient.voided = 0 AND o.voided = 0
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 3785 and os.value_coded in (1034,1084)
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 AND o.person_id in (
												select distinct os.person_id
												from obs os
												where os.concept_id =4666 and os.value_coded = 4324
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST(' #endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
									   )

									   UNION
									   (
SELECT  patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender , age_group
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST(' #endDate#' AS DATE), person.birthdate)/365) AS Age,
														  -- (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
										
											 AND patient.voided = 0 AND o.voided = 0
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 3785 and os.value_coded in (1034,1084)
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 AND o.person_id in (
												select distinct os.person_id
												from obs os
												where os.concept_id =4666 and os.value_coded = 4665
												
												AND patient.voided = 0 AND o.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST(' #endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
									   )

SELECT Patient_Identifier, Patient_Name, Age, Gender, age_group
FROM (

		(SELECT patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   observed_age_group.sort_order AS sort_order

						from obs o
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND patient.voided = 0 AND o.voided = 0
								 
								 
								 -- Clients who switched
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 2267 and os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								 -- Observations inside the HIV care and Treatment Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id = 2403
								 )) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.Age)

) AS HTS_Status_Detailed

ORDER BY HTS_Status_Detailed.sort_order
			, HTS_Status_Detailed.Gender

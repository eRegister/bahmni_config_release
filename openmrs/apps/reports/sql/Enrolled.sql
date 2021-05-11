 SELECT distinct age_group AS 'AgeGroup'
			, IF(Id IS NULL, 0, SUM(IF(Program_Status = 'Enrolled' AND Gender = 'M', 1, 0))) AS Enrolled_Males
			, IF(Id IS NULL, 0, SUM(IF(Program_Status = 'Enrolled' AND Gender = 'F', 1, 0))) AS Enrolled_Females
	FROM(
   select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order,
									   'Enrolled' as Program_Status

                from obs o
						-- CLIENTS ENROLLED ON ART
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND (o.concept_id = 2223 
						 AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						 AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						 )
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.person_id not in (
							select distinct os.person_id from obs os
							where os.concept_id = 3634 
							AND os.value_coded = 2095 
							AND MONTH(os.obs_datetime) >= MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(os.obs_datetime) >= YEAR(CAST('#endDate#' AS DATE))
						 )	
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
						 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages')AS Enrolled_ART_Clients
				   GROUP BY age_group
						
	
SELECT  HTS_TOTALS_COLS_ROWS.Total_Outcome
        ,HTS_TOTALS_COLS_ROWS.HIV_Infected
		,HTS_TOTALS_COLS_ROWS.HIV_Uninfected
		,HTS_TOTALS_COLS_ROWS.HIV_Final_Status_Unknown
		,HTS_TOTALS_COLS_ROWS.Died_Without_Status_Known
		

FROM ( 
						-- //TODO: Fix the totals
			(SELECT     'Total' AS Total_Outcome
						,IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0,SUM(IF(HTS_STATUS_DRVD_ROWS.Outcome = 'HIV-Infected',1,0))) As HIV_Infected
						,IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0,SUM(IF(HTS_STATUS_DRVD_ROWS.Outcome = 'HIV-Uninfected',1,0))) As HIV_Uninfected
						,IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0,SUM(IF(HTS_STATUS_DRVD_ROWS.Outcome = 'HIV-Final Status Unknown',1,0))) As HIV_Final_Status_Unknown 
						,IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0,SUM(IF(HTS_STATUS_DRVD_ROWS.Outcome = 'Died Without Status Known',1,0)))  As Died_Without_Status_Known
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0,SUM(1)) as 'Total'
						, HTS_STATUS_DRVD_ROWS.sort_order
			FROM (

				(SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Infected' AS 'Outcome',sort_order
							 
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
											  AND o.concept_id =4589
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
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
									) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)


UNION

(	SELECT Id ,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Uninfected' AS 'Outcome',sort_order
							 
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
											  AND o.concept_id =4589
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
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
										
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)
 UNION
   
   (	SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'HIV-Final Status Unknown' AS 'Outcome',sort_order
							 
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
											  AND o.concept_id =4589
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
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
									
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)

UNION

	   (SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'Died Without Status Known' AS 'Outcome',sort_order
							 
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
											  AND o.concept_id =4589
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
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages'
									
										 ) AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.Age)
						


			) AS HTS_STATUS_DRVD_ROWS

			GROUP BY HTS_STATUS_DRVD_ROWS.age_group, HTS_STATUS_DRVD_ROWS.Gender
			ORDER BY HTS_STATUS_DRVD_ROWS.sort_order)
	) AS HTS_TOTALS_COLS_ROWS
ORDER BY HTS_TOTALS_COLS_ROWS.sort_order
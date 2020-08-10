SELECT TOTALS_COLS_ROWS.AgeGroup 
		, TOTALS_COLS_ROWS.Received 
		, TOTALS_COLS_ROWS.Pending 	
        , TOTALS_COLS_ROWS.Total

FROM (
 
(SELECT INDEX_STATUS_DRVD_ROWS.age_group AS 'AgeGroup'                  
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.VL_Results_Status = 'Received' , 1, 0))) AS Received                      
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.VL_Results_Status = 'Pending' , 1, 0))) AS Pending						
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0,  SUM(1)) as 'Total' 
						, INDEX_STATUS_DRVD_ROWS.sort_order
			FROM (  
				

-- CLIENTS WITH DETECTABLE VL
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, "Received" AS 'VL_Results_Status','High VL Routine' as 'Client Enrollment Status', sort_order
FROM  
		 
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   o.value_numeric AS vl_result,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.concept_id = 4267 AND MONTH(o.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
								 

								--  CLients with with viral load results
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4268 AND MONTH(os.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						    WHERE observed_age_group.report_group_name = 'Modified_Ages'
                                                            -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id IN (2403,4273)
								 )) AS INDEX_CLIENTS
		ORDER BY INDEX_CLIENTS.Age)  

UNION

(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, "Pending" AS 'VL_Results_Status','High VL Routine' as 'Client Enrollment Status', sort_order
FROM  
		 
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   o.value_numeric AS vl_result,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.concept_id = 4267 AND MONTH(o.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
								 

								--  CLients with with viral load results
								 AND o.person_id not in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4268 AND MONTH(os.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						    WHERE observed_age_group.report_group_name = 'Modified_Ages'
                                                            -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id IN (2403,4273)
								 )) AS INDEX_CLIENTS
		ORDER BY INDEX_CLIENTS.Age)  



) AS INDEX_STATUS_DRVD_ROWS

GROUP by INDEX_STATUS_DRVD_ROWS.age_group
ORDER BY INDEX_STATUS_DRVD_ROWS.sort_order)

UNION ALL

(SELECT 'Total' AS 'AgeGroup'                                  
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.VL_Results_Status = 'Received' , 1, 0))) AS Received                      
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.VL_Results_Status = 'Pending' , 1, 0))) AS Pending							
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0,  SUM(1)) as 'Total'  
						, 99 AS sort_order
			FROM (				

-- CLIENTS WITH DETECTABLE VL
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, "Received" AS 'VL_Results_Status','High VL Routine' as 'Client Enrollment Status'
FROM  
		 
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   o.value_numeric AS vl_result 

						from obs o
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS 
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.concept_id = 4267 AND MONTH(o.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))


								--  CLients with with viral load results
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4268 AND MONTH(os.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
									AND patient.voided = 0 AND o.voided = 0
								 )
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
                                 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
                                -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id IN (2403,4273)
								 )

								) AS INDEX_CLIENTS_COLS )  

UNION

(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, "Pending" AS 'VL_Results_Status','High VL Routine' as 'Client Enrollment Status'
FROM  
		 
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   o.value_numeric AS vl_result 

						from obs o
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS 
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.concept_id = 4267 AND MONTH(o.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))


								--  CLients with with viral load results
								 AND o.person_id not in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4268 AND MONTH(os.value_datetime) IN (MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)), MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -0 MONTH)))
									AND patient.voided = 0 AND o.voided = 0
								 )
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
                                 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
                                -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id IN (2403,4273)
								 )

								) AS INDEX_CLIENTS_COLS ) 
				
        ) AS CLIENTS_OFFERED_INDEXING_COLS
    )

) AS TOTALS_COLS_ROWS

ORDER BY TOTALS_COLS_ROWS.sort_order

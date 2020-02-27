SELECT TOTALS_COLS_ROWS.AgeGroup
		, TOTALS_COLS_ROWS.Gender
		, TOTALS_COLS_ROWS.Detectable_VL
		, TOTALS_COLS_ROWS.Linked
		, TOTALS_COLS_ROWS.Not_Linked
		, TOTALS_COLS_ROWS.Reffered
        , TOTALS_COLS_ROWS.Total

FROM (

(SELECT INDEX_STATUS_DRVD_ROWS.age_group AS 'AgeGroup'
					, INDEX_STATUS_DRVD_ROWS.Gender 
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.Patient_Health_Status = '>=20ml', 1, 0))) AS Detectable_VL                      
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.Patient_Health_Status = 'Linked', 1, 0))) AS Linked					
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.Patient_Health_Status = 'Not_Linked', 1, 0))) AS Not_Linked							
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(INDEX_STATUS_DRVD_ROWS.Patient_Health_Status = 'Referred', 1, 0))) AS Reffered					
						, IF(INDEX_STATUS_DRVD_ROWS.Id IS NULL, 0,  SUM(1)) as 'Total' 
						, INDEX_STATUS_DRVD_ROWS.sort_order
			FROM ( 
(SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, '>=20ml' AS 'Patient_Health_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
 
						 INNER JOIN patient ON o.person_id = patient.patient_id
						 AND o.concept_id = 4273  
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						  
                         AND o.person_id in (
							select distinct os.person_id
							from obs os
							where os.concept_id = 4266 and os.value_coded = 4265
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )						  				 
 						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('20200229' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS ARTClients_HIV_Status
ORDER BY ARTClients_HIV_Status.Age)

UNION
 
(SELECT id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Linked' AS 'Patient_Health_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						  
						 AND o.person_id in (
							select distinct os.person_id
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2146
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )
						  
 						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('20200229' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
ORDER BY HTSClients_HIV_Status.Age)

UNION
 
(SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Not_Linked' AS 'Patient_Health_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
						 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 
						  
						 AND o.person_id in (
							select distinct os.person_id 
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2147
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )
						 
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 INNER JOIN reporting_age_group AS observed_age_group ON
						 
						 CAST('20200229' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
ORDER BY HTSClients_HIV_Status.Age)

UNION
 
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Referred' AS 'Patient_Health_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
						 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 
						  
						 AND o.person_id in (
							select distinct os.person_id 
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2922
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 ) 
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 INNER JOIN reporting_age_group AS observed_age_group ON

						 CAST('20200229' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_Status
ORDER BY HTSClients_HIV_Status.Age) 

) AS INDEX_STATUS_DRVD_ROWS

GROUP by INDEX_STATUS_DRVD_ROWS.age_group,INDEX_STATUS_DRVD_ROWS.Gender
ORDER BY INDEX_STATUS_DRVD_ROWS.sort_oeder)

UNION ALL

	(SELECT 'Total' AS 'AgeGroup'
					, 'All' AS 'Gender'                
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.Patient_Health_Status = '>=20ml', 1, 0))) AS Detectable_VL                      
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.Patient_Health_Status = 'Linked', 1, 0))) AS Linked                      
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.Patient_Health_Status = 'Not_Linked', 1, 0))) AS Not_Linked									
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(IF(CLIENTS_OFFERED_INDEXING_COLS.Patient_Health_Status = 'Referred', 1, 0))) AS Reffered						
						, IF(CLIENTS_OFFERED_INDEXING_COLS.Id IS NULL, 0, SUM(1)) as 'Total'
						, 99 AS sort_order
			FROM (
 
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender,'>=20ml' AS 'Patient_Health_Status'
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender
                from obs o
 
						 INNER JOIN patient ON o.person_id = patient.patient_id
						 AND o.concept_id = 4273  
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						  
                         AND o.person_id in (
							select distinct os.person_id
							from obs os
							where os.concept_id = 4266 and os.value_coded = 4265
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )						  				 
 						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 ) AS Clients_Offered_Indexing
)

UNION
 
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, 'Linked' AS 'Patient_Health_Status'
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender

                from obs o
 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						  
						 AND o.person_id in (
							select distinct os.person_id
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2146
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )
						  
 						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 
						  ) AS Clients_Offered_Indexing
)

UNION 
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, 'Not_Linked' AS 'Patient_Health_Status'
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender

                from obs o
						 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 
						 
						 AND o.person_id in (
							select distinct os.person_id 
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2147
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 )
						 
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 ) AS Clients_Offered_Indexing
)

UNION

 
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, 'Referred' AS 'Patient_Health_Status'
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('20200229' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender

                from obs o 
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 
						  
						 AND o.person_id in (
							select distinct os.person_id 
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2922
							AND os.obs_datetime BETWEEN CAST('20190201' AS DATE) AND CAST('20200229' AS DATE)
						 ) 
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						) AS Clients_Offered_Indexing

            )
        ) AS CLIENTS_OFFERED_INDEXING_COLS
    )

) AS TOTALS_COLS_ROWS

ORDER BY TOTALS_COLS_ROWS.sort_order

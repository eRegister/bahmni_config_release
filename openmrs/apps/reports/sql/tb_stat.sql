      
SELECT HTS_TOTALS_COLS_ROWS.AgeGroup
		, HTS_TOTALS_COLS_ROWS.Gender
		, HTS_TOTALS_COLS_ROWS.New_New_Positives
		, HTS_TOTALS_COLS_ROWS.New_New_Negatives
		, HTS_TOTALS_COLS_ROWS.New_Known_Positives
		, HTS_TOTALS_COLS_ROWS.New_Known_Negatives
		, HTS_TOTALS_COLS_ROWS.Relapsed_New_Positives
		, HTS_TOTALS_COLS_ROWS.Relapsed_New_Negatives
		, HTS_TOTALS_COLS_ROWS.Relapsed_Known_Positives
		, HTS_TOTALS_COLS_ROWS.Relapsed_Known_Negatives
		, HTS_TOTALS_COLS_ROWS.Total

FROM (

			(SELECT HTS_STATUS_DRVD_ROWS.age_group AS 'AgeGroup'
					, HTS_STATUS_DRVD_ROWS.Gender
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS.TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'New Positive', 1, 0))) AS New_New_Positives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS.TB_Treatment_History = 'New Patient' 		
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'New Negative', 1, 0))) AS New_New_Negatives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS. TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'Known Positive', 1, 0))) AS New_Known_Positives				
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS. TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'Known Negative', 1, 0))) AS New_Known_Negatives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS.TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'New Positive', 1, 0))) AS Relapsed_New_Positives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS.TB_Treatment_History = 'Relapsed' 		
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'New Negative', 1, 0))) AS Relapsed_New_Negatives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS. TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'Known Positive', 1, 0))) AS Relapsed_Known_Positives				
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_ROWS. TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_ROWS.HIV_STATUS = 'Known Negative', 1, 0))) AS Relapsed_Known_Negatives
						, IF(HTS_STATUS_DRVD_ROWS.Id IS NULL, 0, SUM(1)) as 'Total'
						, HTS_STATUS_DRVD_ROWS.sort_order
				
			FROM (

					(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'New Patient'AS 'TB_Treatment_History','Known Positive'AS 'HIV_STATUS',sort_order
							 
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
											  AND o.concept_id =3785 and o.value_coded=1034
											 AND patient.voided = 0 AND o.voided = 0
										     AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4323
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											  AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.HIV_STATUS, HTSClients_HIV_STATUS.Age)


UNION

	(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'New Patient' AS 'TB_Treatment_History','Known Negative'AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										   -- New TB Patient
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1034
											  AND patient.voided = 0 AND o.voided = 0
											  AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											  
											  -- Known Negative HIV Status
											  AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4324
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 -- Not Transferred In
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.HIV_STATUS, HTSClients_HIV_STATUS.Age)

UNION	

	(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'New Patient' AS 'TB_Treatment_History','New Positive' AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										 -- New TB Patient
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1034
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											-- New Positive HIV Status
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4664
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 -- Not Transferred In
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'New Patient' AS 'TB_Treatment_History','New Negative' AS 'HIV_STATUS',sort_order
							 
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
											 -- New TB Patient
											  AND o.concept_id =3785 and o.value_coded=1034
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											
											-- New Negative HIV Status
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4665
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											-- NOt transferred in
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'Relapsed' AS 'TB_Treatment_History','Known Positive' AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										 
										 -- Relapsed TB Patient
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
                                             AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
										
										--  Known Positive HIV Status	 
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4323
												
												AND patient.voided = 0 AND os.voided = 0
											 )
										-- Not Transferred In
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)
UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'Relapsed'AS 'TB_Treatment_History','Known Negative' AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										
										--Relapsed TB Client
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 
										-- KNown Negative HIV Status	 
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4324
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )

										-- Not Transferred In
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT  Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group, 'Relapsed' AS 'TB_Treatment_History' ,'New Positive' AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										-- Relapsed TB Client
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 
										-- New Positive HIV Status
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4664
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
										-- Not Transferred In
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, age_group,'Relapsed' AS 'TB_Treatment_History','New Negative'AS 'HIV_STATUS',sort_order
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender,
														   observed_age_group.name AS age_group,
														   observed_age_group.sort_order AS sort_order
  
									from obs o
										-- Relapsed TB Patient
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											
										-- New Negative HIV Status
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4665
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
											 INNER JOIN reporting_age_group AS observed_age_group ON
											  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
											  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
									     WHERE observed_age_group.report_group_name = 'Modified_Ages') AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)								

			) AS HTS_STATUS_DRVD_ROWS

			GROUP BY HTS_STATUS_DRVD_ROWS.age_group, HTS_STATUS_DRVD_ROWS.Gender
			ORDER BY HTS_STATUS_DRVD_ROWS.sort_order)
			
			
	UNION ALL

											-- NB:ALL CRITERIAS BELOW ARE THE SAME AS THE ABOVE
			(SELECT 'Total' AS 'AgeGroup'
					, 'All' AS 'Gender'
						
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS.TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'New Positive', 1, 0))) AS New_New_Positives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS.TB_Treatment_History = 'New Patient' 		
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'New Negative', 1, 0))) AS New_New_Negatives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS. TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'Known Positive', 1, 0))) AS New_Known_Positives				
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS. TB_Treatment_History = 'New Patient'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'Known Negative', 1, 0))) AS New_Known_Negatives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS.TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'New Positive', 1, 0))) AS Relapsed_New_Positives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS.TB_Treatment_History = 'Relapsed' 		
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'New Negative', 1, 0))) AS Relapsed_New_Negatives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS. TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'Known Positive', 1, 0))) AS Relapsed_Known_Positives				
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(IF(HTS_STATUS_DRVD_COLS. TB_Treatment_History = 'Relapsed'
							AND HTS_STATUS_DRVD_COLS.HIV_STATUS = 'Known Negative', 1, 0))) AS Relapsed_Known_Negatives
						, IF(HTS_STATUS_DRVD_COLS.Id IS NULL, 0, SUM(1)) as 'Total'
						, 99 AS sort_order
			FROM (

					(SELECT  Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'New Patient' AS 'TB_Treatment_History','Known Positive' AS 'HIV_STATUS'
							 
					FROM
					
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														  
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1034
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4323
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											  AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.HIV_STATUS, HTSClients_HIV_STATUS.Age)


UNION

	(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'New Patient' AS 'TB_Treatment_History','Known Negative' AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											INNER JOIN patient ON o.person_id = patient.patient_id 
											AND o.concept_id =3785 and o.value_coded=1034
											AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4324
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
					ORDER BY HTSClients_HIV_STATUS.HIV_STATUS, HTSClients_HIV_STATUS.Age)

UNION	

	(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'New Patient' AS 'TB_Treatment_History','New Positive' AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1034
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4664
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'New Patient' AS 'TB_Treatment_History','New Negative' AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											INNER JOIN patient ON o.person_id = patient.patient_id 
											AND o.concept_id =3785 and o.value_coded=1034
											AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4665
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION
(SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'Relapsed' AS 'TB_Treatment_History','Known Positive'AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											INNER JOIN patient ON o.person_id = patient.patient_id 
											AND o.concept_id =3785 and o.value_coded=1084
											AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4323
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)
UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'Relapsed' AS 'TB_Treatment_History','Known Negative'AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											INNER JOIN patient ON o.person_id = patient.patient_id 
											AND o.concept_id =3785 and o.value_coded=1084
											AND patient.voided = 0 AND o.voided = 0
											AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4324
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT  Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender, 'Relapsed' AS 'TB_Treatment_History','New Positive' AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4664
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)

UNION

   (SELECT Id,patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age , Gender,'Relapsed' AS 'TB_Treatment_History','New Negative' AS 'HIV_STATUS'
							 
					FROM
									(select distinct patient.patient_id AS Id,
														   patient_identifier.identifier AS patientIdentifier,
														   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
														   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											         	 
														   person.gender AS Gender
														   
  
									from obs o
										
											 INNER JOIN patient ON o.person_id = patient.patient_id 
											  AND o.concept_id =3785 and o.value_coded=1084
											 AND patient.voided = 0 AND o.voided = 0
											 AND (o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
											 AND o.person_id in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 4666 and os.value_coded =4665
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											   AND o.person_id not in (
												select distinct os.person_id 
												from obs os
												where os.concept_id = 	3772 and os.value_coded =2095
												AND (os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE))
												AND patient.voided = 0 AND os.voided = 0
											 )
											 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
											 INNER JOIN person_name ON person.person_id = person_name.person_id
											 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
									)AS HTSClients_HIV_STATUS
										 ORDER BY HTSClients_HIV_Status.Age
)					
					

) AS HTS_STATUS_DRVD_COLS
		)
		
	) AS HTS_TOTALS_COLS_ROWS
ORDER BY HTS_TOTALS_COLS_ROWS.sort_order


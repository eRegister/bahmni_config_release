SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Routine' AS VLMonitoringType, vl_result AS VL_Result, sort_order
FROM (

		(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, vl_result AS VL_Result, sort_order
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
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS
								INNER JOIN patient ON o.person_id = patient.patient_id
								AND o.concept_id = 2254 and o.voided=0
								AND o.obs_id in (
										select os.obs_id
										from obs os
										where os.concept_id=2254
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 2254 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
								)
								AND person_id in (
										select os.person_id
										from obs os
										where os.concept_id=4280
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4280 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
										-- ROUTINE VL MONITORING TYPE
										and os.value_coded = 4281
								)
								AND o.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
								INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
									CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						    WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Client_With_Suppressed_VL
		ORDER BY Client_With_Suppressed_VL.Age)

		UNION

		(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, IF(vl_result = 4264, 'LessThan20', 'Undetectable') AS VL_Result, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   o.value_coded AS vl_result,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS
								INNER JOIN patient ON o.person_id = patient.patient_id
								AND o.concept_id = 4266 and o.voided=0
								AND o.obs_id in (
										select os.obs_id
										from obs os
										where os.concept_id=4266
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4266 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)										
										and os.value_coded in (4264, 4263)
								)
								AND person_id in (
										select os.person_id
										from obs os
										where os.concept_id=4280
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4280 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)										
										-- ROUTINE VL MONITORING TYPE
										and os.value_coded = 4281
								)			
								AND o.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
								INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
									CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Client_With_Suppressed_VL_Coded
		ORDER BY Client_With_Suppressed_VL_Coded.Age)
) AS Routine_SuppressedVLResults

UNION

SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Targeted' AS VLMonitoringType, vl_result AS VL_Result, sort_order
FROM (

		(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, vl_result AS VL_Result, sort_order
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
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS
								INNER JOIN patient ON o.person_id = patient.patient_id
								AND o.concept_id = 2254 and o.voided=0
								AND o.obs_id in (
										select os.obs_id
										from obs os
										where os.concept_id=2254
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 2254 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
								)
								AND person_id in (
										select os.person_id
										from obs os
										where os.concept_id=4280
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4280 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
										-- TARGETED VL MONITORING TYPE
										and os.value_coded = 4282
								)
								AND o.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
								INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
									CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						    WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Client_With_Suppressed_VL
		ORDER BY Client_With_Suppressed_VL.Age)

		UNION

		(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, IF(vl_result = 4264, 'LessThan20', 'Undetectable') AS VL_Result, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   o.value_coded AS vl_result,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- CLIENTS WITH A VIRAL LOAD RESULT DOCUMENTED WITHIN THE LAST 12 MONTHS
								INNER JOIN patient ON o.person_id = patient.patient_id
								AND o.concept_id = 4266 and o.voided=0
								AND o.obs_id in (
										select os.obs_id
										from obs os
										where os.concept_id=4266
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4266 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
										and os.value_coded in (4264, 4263)
								)
								AND person_id in (
										select os.person_id
										from obs os
										where os.concept_id=4280
										and os.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
										and os.obs_id in (
											select observation_id
											from 
												(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
												from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4280 and oss.voided=0
												and oss.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
												group by p.person_id) as latest_vl_observations
										)
										-- TARGETED VL MONITORING TYPE
										and os.value_coded = 4282
								)			
								AND o.obs_datetime BETWEEN DATE(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -12 MONTH)) AND CAST('#endDate#' AS DATE)
								INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
									CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Client_With_Suppressed_VL_Coded
		ORDER BY Client_With_Suppressed_VL_Coded.Age)
) AS Targeted_SuppressedVLResults

SELECT TotalPatientAppointmentStatus.AgeGroup
		, TotalPatientAppointmentStatus.Defaulted_Males
		, TotalPatientAppointmentStatus.Defaulted_Females
		, TotalPatientAppointmentStatus.Total
FROM 

(

(SELECT PatientAppointmentStatus.age_group AS 'AgeGroup'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(IF(PatientAppointmentStatus.App_Status = 'Defaulted' AND PatientAppointmentStatus.Gender = 'M', 1, 0))) AS 'Defaulted_Males'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(IF(PatientAppointmentStatus.App_Status = 'Defaulted' AND PatientAppointmentStatus.Gender = 'F', 1, 0))) AS 'Defaulted_Females'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(1)) as 'Total'
		, PatientAppointmentStatus.sort_order
FROM

(SELECT  Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, age_group, Gender, App_Status, sort_order

FROM
        (
			SELECT distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   observed_age_group.name AS age_group,
											   person.gender AS Gender,
											   'Defaulted' AS App_Status,
											   observed_age_group.sort_order AS sort_order
			FROM obs o
									INNER JOIN patient ON o.person_id = patient.patient_id and o.concept_id = 3752 
									
									and o.value_datetime in
									(				
										select latestFU
										from
											(
												select distinct os.person_id, given_name, family_name, max(os.value_datetime) AS latestFU, datediff(CAST('#endDate#' AS DATE), max(value_datetime)) AS Num_Days
												from obs os
												inner join person_name pn on os.person_id = pn.person_id
												inner join patient p  on pn.person_id = p.patient_id and pn.voided = 0
												inner join person ps on ps.person_id = p.patient_id and ps.voided = 0
												where os.concept_id = 3752 
												group by os.person_id
												having Num_Days > 0 and Num_Days <= 28
											) AS Defauled
									)									
									and o.person_id in
									(				
										select person_id
										from
											(
												select distinct os.person_id, given_name, family_name, max(os.value_datetime) AS latestFU, datediff(CAST('#endDate#' AS DATE), max(value_datetime)) AS Num_Days
												from obs os
												inner join person_name pn on os.person_id = pn.person_id
												inner join patient p  on pn.person_id = p.patient_id and pn.voided = 0
												inner join person ps on ps.person_id = p.patient_id and ps.voided = 0
												where os.concept_id = 3752 
												group by os.person_id
												having Num_Days > 0 and Num_Days <= 28
											) AS Defauled
									)
									AND o.person_id not in (																		 
												select distinct os.person_id 
													from obs os
													where (os.concept_id = 4155 and os.value_coded = 2146 and obs_datetime < '#endDate#' and person_id not in 
													(select person_id from
														(select person_id who, max(value_datetime) latest
														from obs 
														where concept_ID = 2266
																			group by person_id) one,
														
														 (
														select person_id,obs_datetime 
														from obs 
														where concept_id = 3843 ) two
														
														where who = person_id
														and DATE(obs_datetime) > DATE(latest))
														)													  														 							 
												)
									AND o.person_id not in (
												select person_id 
												from person 
												where death_date <= '#endDate#' 
												and dead = 1
									)
									
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
									 INNER JOIN reporting_age_group AS observed_age_group ON CAST('#endDate#' AS DATE) 
									 BETWEEN
									(DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
										AND 
									(DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))

			WHERE observed_age_group.report_group_name = 'Modified_Ages'
		) AS Patient_MissedAppointments
		
) AS PatientAppointmentStatus

GROUP BY PatientAppointmentStatus.age_group
ORDER BY PatientAppointmentStatus.sort_order)

UNION ALL


(SELECT 'Total' AS 'AgeGroup'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(IF(PatientAppointmentStatus.App_Status = 'Defaulted' AND PatientAppointmentStatus.Gender = 'M', 1, 0))) AS 'Defaulted_Males'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(IF(PatientAppointmentStatus.App_Status = 'Defaulted' AND PatientAppointmentStatus.Gender = 'F', 1, 0))) AS 'Defaulted_Females'
		, IF(PatientAppointmentStatus.Id IS NULL, 0, SUM(1)) as 'Total'
		, 99 AS 'sort_order'
FROM

(SELECT  Total_MissedAppointments.Id
			, Total_MissedAppointments.patientIdentifier AS "Patient Identifier"
			, Total_MissedAppointments.patientName AS "Patient Name"
			, Total_MissedAppointments.Age
			, Total_MissedAppointments.Gender
			, Total_MissedAppointments.App_Status
FROM
        (
			SELECT distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   person.gender AS Gender,
											   'Defaulted' AS App_Status

			FROM obs o
									INNER JOIN patient ON o.person_id = patient.patient_id and o.concept_id = 3752 and o.value_datetime in
									(				
										select latestFU
										from
											(
												select distinct os.person_id, given_name, family_name, max(os.value_datetime) AS latestFU, datediff(CAST('#endDate#' AS DATE), max(value_datetime)) AS Num_Days
												from obs os
												inner join person_name pn on os.person_id = pn.person_id
												inner join patient p  on pn.person_id = p.patient_id and pn.voided = 0
												inner join person ps on ps.person_id = p.patient_id and ps.voided = 0
												where os.concept_id = 3752 
												group by os.person_id
												having Num_Days > 0 and Num_Days <= 28
											) AS Defauled
									)									
									and o.person_id in
									(				
										select person_id
										from
											(
												select distinct os.person_id, given_name, family_name, max(os.value_datetime) AS latestFU, datediff(CAST('#endDate#' AS DATE), max(value_datetime)) AS Num_Days
												from obs os
												inner join person_name pn on os.person_id = pn.person_id
												inner join patient p  on pn.person_id = p.patient_id and pn.voided = 0
												inner join person ps on ps.person_id = p.patient_id and ps.voided = 0
												where os.concept_id = 3752 
												group by os.person_id
												having Num_Days > 0 and Num_Days <= 28
											) AS Defauled
									)
									AND o.person_id not in (																		 
												select distinct os.person_id 
													from obs os
													where (os.concept_id = 4155 and os.value_coded = 2146 and obs_datetime < '#endDate#' and person_id not in 
													(select person_id from
														(select person_id who, max(value_datetime) latest
														from obs 
														where concept_ID = 2266
																			group by person_id) one,
														
														 (
														select person_id,obs_datetime 
														from obs 
														where concept_id = 3843 ) two
														
														where who = person_id
														and DATE(obs_datetime) > DATE(latest))
														)													  														 							 
												)
									AND o.person_id not in (
												select person_id 
												from person 
												where death_date <= '#endDate#' 
												and dead = 1
															)
									 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
									 INNER JOIN person_name ON person.person_id = person_name.person_id
									 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
		) AS Total_MissedAppointments
) AS PatientAppointmentStatus)

) AS TotalPatientAppointmentStatus

ORDER BY TotalPatientAppointmentStatus.sort_order;

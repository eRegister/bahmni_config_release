SELECT DISTINCT Patient_Identifier, Patient_Name, Age, Gender, age_group, HIV_Testing_Initiation , Testing_History , HIV_Status,Testing_Strategy,Mode_of_Entry,Linked_To_Care_Status
FROM (

		(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4228 and os.value_coded = 4227
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 -- REPEAT TESTER, HAS A HISTORY OF PREVIOUS TESTING
								 AND o.person_id in (
									select distinct os.person_id
									from obs os
									where os.concept_id = 2137 and os.value_coded = 2146
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1 AND person_name.voided = 0
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred = 1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								 -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id = 2385
								 )) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)


		UNION

		(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'New' AS 'Testing_History' , HIV_Status, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4228 and os.value_coded = 4227
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 -- NEW TESTER, DOES NOT HAVE A HISTORY OF PREVIOUS TESTING
								 AND o.person_id in (
									select distinct os.person_id
									from obs os
									where os.concept_id = 2137 and os.value_coded = 2147
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1 AND person_name.voided = 0
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred = 1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								 -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id = 2385
								 )) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)


		UNION

		(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4228 and os.value_coded = 4226
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 -- REPEAT TESTER, HAS A HISTORY OF PREVIOUS TESTING
								 AND o.person_id in (
									select distinct os.person_id
									from obs os
									where os.concept_id = 2137 and os.value_coded = 2146
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )						 
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1 AND person_name.voided = 0
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred = 1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								 -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id = 2385
								 )) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

		UNION

		(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'New' AS 'Testing_History' , HIV_Status, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = o.value_coded and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165
								 AND patient.voided = 0 AND o.voided = 0
								 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 AND o.person_id in (
									select distinct os.person_id 
									from obs os
									where os.concept_id = 4228 and os.value_coded = 4226
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )
								 
								 -- NEW TESTER, DOES NOT HAVE A HISTORY OF PREVIOUS TESTING
								 AND o.person_id in (
									select distinct os.person_id
									from obs os
									where os.concept_id = 2137 and os.value_coded = 2147
									AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
									AND patient.voided = 0 AND o.voided = 0
								 )						 
								 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1 AND person_name.voided = 0
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred = 1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								 -- Observations inside the HIV Testing and Couseling Form
								 AND o.obs_group_id in (
									select og.obs_id from obs og where og.concept_id = 2385
								 )) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	) AS HTS_Status_Detailed

	LEFT OUTER JOIN 
	(
	-- testing strategy 

	SELECT a.person_id,case 
	WHEN a.value_coded = 4847 then 'Rapid Test'
	WHEN a.value_coded = 4822 then 'Self Test'
	ELSE 'Other Test' end as 'Testing_Strategy'
	FROM obs a
	INNER JOIN 
		(select o.person_id,max(CAST(obs_datetime AS DATE)) maxdate 
		from obs o 
		where obs_datetime <= '#endDate#'
		and o.concept_id = 4845
        AND o.voided = 0
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
	where a.concept_id = 4845 
	and CAST(a.obs_datetime AS DATE) = maxdate
    AND a.voided = 0
	)testing ON HTS_Status_Detailed.Id = testing.person_id
	
	LEFT OUTER JOIN 
	(
	select a.person_id,case 
	when a.value_coded = 4234 then 'Antiretroviral'
	when a.value_coded = 4233 then 'Anti Natal Care'
	when a.value_coded = 2191 then 'Outpatient'
	when a.value_coded = 2190 then 'TB Entry Point'
	when a.value_coded = 4235 then 'Male Circumcision'
	when a.value_coded = 4236 then 'Adolescent'
	when a.value_coded = 2192 then 'Inpatient'
	when a.value_coded = 3632 then 'PEP'
	when a.value_coded = 2139 then 'STI'
	when a.value_coded = 4788 then 'Pediatric Services'
	when a.value_coded = 4789 then 'Malnutrition'
	when a.value_coded = 4790 then 'Subsequent ANC'
	when a.value_coded = 4791 then 'Emergency ward'
	when a.value_coded = 4792 then 'Index Testing'
	when a.value_coded = 4796 then 'Other Cummunity'
	when a.value_coded = 4237 then 'Self Testing'
	when a.value_coded = 4816 then 'PrEP'
	when a.value_coded = 2143 then 'Other'
	else 'Unknown Entry Mode' end as 'Mode_of_Entry'
	FROM obs a
	INNER JOIN 
		(select o.person_id,max(CAST(obs_datetime AS DATE)) maxdate 
		from obs o 
		where obs_datetime <= '#endDate#'
		and o.concept_id = 4238
        AND o.voided = 0
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
	where a.concept_id = 4238 
    AND a.voided = 0
	and CAST(a.obs_datetime AS DATE) = maxdate
	)entry ON HTS_Status_Detailed.Id = entry.person_id


	LEFT OUTER JOIN 
	(
      SELECT person_id,  Linked_To_Care_Status
      FROM
        ( -- referrals from retesting form
	select a.person_id,case 
	when a.value_coded = 2146 then 'Linked to Care'
	when a.value_coded = 2922 then 'Referred'
    when a.value_coded = 2147 then 'Not Linked'
	else 'Not Applicable' end as 'Linked_To_Care_Status'
	FROM obs a
	INNER JOIN 
		(select o.person_id,max(CAST(obs_datetime AS DATE)) maxdate 
		from obs o 
		where obs_datetime <= '#endDate#'
		and o.concept_id = 4239
        AND o.voided = 0
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
	where a.concept_id = 4239 
    AND a.voided = 0
	and CAST(a.obs_datetime AS DATE) = maxdate

    UNION
    -- referrals from HTS form
    select a.person_id, 'Referred'
	FROM obs a
	INNER JOIN 
		(select o.person_id,max(CAST(obs_datetime AS DATE)) maxdate 
		from obs o 
		where obs_datetime <= '#endDate#'
		and o.concept_id = 4756 AND o.value_coded = 2922
        AND o.voided = 0
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
	where a.concept_id = 4756 AND a.value_coded = 2922
	and CAST(a.obs_datetime AS DATE) = maxdate
    AND a.voided = 0 )appp


	)linked ON HTS_Status_Detailed.Id = linked.person_id






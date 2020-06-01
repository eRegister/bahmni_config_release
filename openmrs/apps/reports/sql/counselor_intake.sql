SELECT DISTINCT
		location_name
		, Identifier
		, Name
		, Gender
		, Age
		, Status
FROM 
(

		SELECT DISTINCT
				location_name
				, id
				, identifier as Identifier
				, name as Name
				, gender as Gender
				, age as Age
				, status as Status

		FROM
		(

			SELECT DISTINCT
					reg.location_name
					, reg.id
					, reg.name
					, reg.gender
					, reg.age
					, reg.identifier
					, IF(init.id is not null, 'Intake', 'No Intake') AS status
			FROM
					((SELECT DISTINCT
							p.person_id as id,
							concat(pn.given_name,' ', ifnull(pn.family_name,'')) as name,
							p.gender AS gender,				
							floor(datediff(CAST('#endDate#' AS DATE), p.birthdate)/365) AS age,				
							pi.identifier as identifier,
							concat("",p.uuid) as uuid,
							concept_id,
							l.name as location_name
					FROM visit v
							JOIN person_name pn on v.patient_id = pn.person_id and pn.voided=0
							JOIN person p on p.person_id = v.patient_id
							JOIN patient_identifier pi on v.patient_id = pi.patient_id and pi.identifier_type=5
							JOIN patient_identifier_type pit on pi.identifier_type = pit.patient_identifier_type_id
							JOIN encounter en on en.visit_id = v.visit_id and en.voided=0
							JOIN obs o on o.encounter_id=en.encounter_id				
							JOIN location l on v.location_id = l.location_id and l.retired=0
					WHERE en.encounter_datetime <= CAST('#endDate#' AS DATE)and o.date_created <= CAST('#endDate#' AS DATE)) reg

					LEFT JOIN 

					(SELECT DISTINCT
							p.person_id as id,
							concat(pn.given_name,' ', ifnull(pn.family_name,'')) as name,
							p.gender AS gender,
							floor(datediff(CAST('#endDate#' AS DATE), p.birthdate)/365) AS age,				
							pi.identifier as identifier,
							concat("",p.uuid) as uuid,
							concept_id,
							l.name as location_name
					FROM visit v
							JOIN person_name pn on v.patient_id = pn.person_id and pn.voided=0
							JOIN person p on p.person_id = v.patient_id
							JOIN patient_identifier pi on v.patient_id = pi.patient_id and pi.identifier_type=5
							JOIN patient_identifier_type pit on pi.identifier_type = pit.patient_identifier_type_id
							JOIN encounter en on en.visit_id = v.visit_id and en.voided=0
							JOIN obs o on o.encounter_id=en.encounter_id and o.concept_id=4270
							JOIN location l on v.location_id = l.location_id and l.retired=0
					WHERE en.encounter_datetime <= CAST('#endDate#' AS DATE) and o.date_created <= CAST('#endDate#' AS DATE)) init
					
					ON reg.id = init.id)			
					
		) AS IntakesRegistered
		GROUP BY IntakesRegistered.id
		HAVING IntakesRegistered.status = 'Intake'


		UNION 

		SELECT DISTINCT
				location_name
				, id
				, identifier as Identifier
				, name as Name
				, gender as Gender
				, age as Age
				, status as Status

		FROM
		(

			SELECT DISTINCT
					reg.location_name
					, reg.id
					, reg.name
					, reg.gender
					, reg.age
					, reg.identifier
					, IF(init.id is not null, 'Intake', 'No Intake') AS status
			FROM
					((SELECT DISTINCT
							p.person_id as id,
							concat(pn.given_name,' ', ifnull(pn.family_name,'')) as name,
							p.gender AS gender,				
							floor(datediff(CAST('#endDate#' AS DATE), p.birthdate)/365) AS age,				
							pi.identifier as identifier,
							concat("",p.uuid) as uuid,
							concept_id,
							l.name as location_name
					FROM visit v
							JOIN person_name pn on v.patient_id = pn.person_id and pn.voided=0
							JOIN person p on p.person_id = v.patient_id
							JOIN patient_identifier pi on v.patient_id = pi.patient_id and pi.identifier_type=5
							JOIN patient_identifier_type pit on pi.identifier_type = pit.patient_identifier_type_id
							JOIN encounter en on en.visit_id = v.visit_id and en.voided=0
							JOIN obs o on o.encounter_id=en.encounter_id				
							JOIN location l on v.location_id = l.location_id and l.retired=0
					WHERE en.encounter_datetime <= CAST('#endDate#' AS DATE)and o.date_created <= CAST('#endDate#' AS DATE)) reg

					LEFT JOIN 

					(SELECT DISTINCT
							p.person_id as id,
							concat(pn.given_name,' ', ifnull(pn.family_name,'')) as name,
							p.gender AS gender,
							floor(datediff(CAST('#endDate#' AS DATE), p.birthdate)/365) AS age,				
							pi.identifier as identifier,
							concat("",p.uuid) as uuid,
							concept_id,
							l.name as location_name
					FROM visit v
							JOIN person_name pn on v.patient_id = pn.person_id and pn.voided=0
							JOIN person p on p.person_id = v.patient_id
							JOIN patient_identifier pi on v.patient_id = pi.patient_id and pi.identifier_type=5
							JOIN patient_identifier_type pit on pi.identifier_type = pit.patient_identifier_type_id
							JOIN encounter en on en.visit_id = v.visit_id and en.voided=0
							JOIN obs o on o.encounter_id=en.encounter_id and o.concept_id=4270
							JOIN location l on v.location_id = l.location_id and l.retired=0
					WHERE en.encounter_datetime <= CAST('#endDate#' AS DATE) and o.date_created <= CAST('#endDate#' AS DATE)) init
					
					ON reg.id = init.id)			
					
		) AS IntakesRegistered
		WHERE IntakesRegistered.id not in (select distinct os.person_id from obs os where os.concept_id=4270)
		GROUP BY IntakesRegistered.id

) AS RegistrationVsIntakes
ORDER BY  RegistrationVsIntakes.id, RegistrationVsIntakes.location_name, RegistrationVsIntakes.status


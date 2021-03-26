SELECT ageGroup,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = '1st_trimester_visits', 1, 0))) AS 1st_trimester_visits,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = '2nd_trimester_visits', 1, 0))) AS 2nd_trimester_visits,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = '3rd_trimester_visits', 1, 0))) AS 3rd_trimester_visits,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'high_risk_pregnancy', 1, 0))) AS high_risk_pregnancy,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'followUp_visit', 1, 0))) AS followUp_visit,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'syphilis_test', 1, 0))) AS syphilis_test,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'tetatus_protected', 1, 0))) AS tetatus_protected,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'Iron_folate', 1, 0))) AS Iron_folate,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'HIV_positive_male_partner', 1, 0))) AS HIV_positive_male_partner,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'TB_Treatment', 1, 0))) AS TB_Treatment,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'ON_INH', 1, 0))) AS ON_INH,
IF(Id IS NULL, 0, SUM(IF(ANC_visit = 'pregnancy_complications', 1, 0))) AS pregnancy_complications
FROM 
	(
		SELECT Id, ANC_visit,ageGroup
		FROM
		(
			-- visits in first trimester 4658 and value_coded in (4659,4660)
			
			select o.person_id as Id,'1st_trimester_visits' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric < 13)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE)) 
			

			UNION
			-- visits in second
			
			select o.person_id as Id,'2nd_trimester_visits' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric >= 13 and value_numeric < 25)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- visits in third
			select o.person_id as Id,'3rd_trimester_visits' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric > 25)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- high risk pregnancies
			
			select o.person_id as Id,'high_risk_pregnancy' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			WHERE concept_id = 4352 and value_coded != 4353
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- total ANC follow up visits 2nd,3rd,4th
			
			select o.person_id as Id,'followUp_visit' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 4658 and value_coded != 4660
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- syphilis test
			
			select o.person_id as Id,'syphilis_test' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 4305 and value_coded in (4306,4307)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- Pregnancies protected against tetatus
			
			select o.person_id as Id,'tetatus_protected' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 4317
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- Provided with Iron 4299 and Folate 4300
			
			select o.person_id as Id,'Iron_folate' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			and concept_id in (4300,4299) AND value_coded in (4668)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- 
			select o.person_id as Id,'HIV_positive_male_partner' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 1741 and value_coded in ( 1738,4323)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- Referred for TB treatment
			select o.person_id as Id,'TB_Treatment' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 4337 and value_coded != 1975
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- Initiated on INH
			select o.person_id as Id,'ON_INH' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where concept_id = 4337 and value_coded = 4333
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- total pregnancy complications
			select o.person_id as Id,'pregnancy_complications' as ANC_visit,'Under20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age < 20
												)
			where (concept_id = 4367 and value_coded != 4368)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			
			UNION
			-- -------------------------------- above 20
			select o.person_id as Id,'1st_trimester_visits' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric < 13)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE)) 
			

			UNION
			-- visits in second
			
			select o.person_id as Id,'2nd_trimester_visits' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric >= 13 and value_numeric < 25)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- visits in third
			select o.person_id as Id,'3rd_trimester_visits' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			AND o.person_id in (select o.person_id from obs o where concept_id = 1923 and value_numeric > 25)
			WHERE concept_id = 4658 and value_coded in (4659,4660)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- high risk pregnancies
			
			select o.person_id as Id,'high_risk_pregnancy' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0 
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			WHERE concept_id = 4352 and value_coded != 4353
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- total ANC follow up visits 2nd,3rd,4th
			
			select o.person_id as Id,'followUp_visit' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 4658 and value_coded != 4660
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- syphilis test
			
			select o.person_id as Id,'syphilis_test' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 4305 and value_coded in (4306,4307)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- Pregnancies protected against tetatus
			
			select o.person_id as Id,'tetatus_protected' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 4317
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- Provided with Iron 4299 and Folate 4300
			
			select o.person_id as Id,'Iron_folate' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			and concept_id in (4300,4299) AND value_coded in (4668)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
			

			UNION
			-- 
			select o.person_id as Id,'HIV_positive_male_partner' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 1741 and value_coded in ( 1738,4323)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- Referred for TB treatment
			select o.person_id as Id,'TB_Treatment' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 4337 and value_coded != 1975
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- Initiated on INH
			select o.person_id as Id,'ON_INH' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where concept_id = 4337 and value_coded = 4333
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))

			UNION
			-- total pregnancy complications
			select o.person_id as Id,'pregnancy_complications' as ANC_visit,'Above20' as ageGroup
			from obs o
			INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
			AND o.person_Id in (select id
								FROM
								( 
									select distinct o.person_id AS Id,
									floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age								   
									from obs o
									INNER JOIN person ON person.person_id = o.person_id AND person.voided = 0
									INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3	
								) as a
								WHERE age >=20
												)
			where (concept_id = 4367 and value_coded != 4368)
			AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE))
			AND YEAR(obs_datetime) =  YEAR(CAST('#endDate#' AS DATE))
		)as a	
	)as ab 
	group by ageGroup
SELECT distinct patientIdentifier AS "Patient Identifier", patientName AS "Patient Name"

FROM
        (
			SELECT distinct 
							p.identifier AS patientIdentifier,
							concat(pn.given_name, ' ', pn.family_name) AS patientName
							
			FROM obs o
			INNER JOIN patient_identifier p ON o.person_id = p.patient_id 
			INNER JOIN person_name pn ON p.patient_id = pn.person_id
			AND o.person_id not in
			(				
				select person_id 
				from obs 
				where (concept_id = 4270 and concept_id = 2397)
				and obs_datetime <= cast(:endDate as date)
				and voided = 0
			)								
			AND o.voided = 0
			
		) AS no_intakes

ORDER BY 2;


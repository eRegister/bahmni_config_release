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
										select person_id from obs where concept_id = 2249
									)								
									
									WHERE p.identifier_type = 5 
									AND o.voided = 0
			
		) AS Patient_MissedAppointments

ORDER BY 2;


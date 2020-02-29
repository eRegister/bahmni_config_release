SELECT Id,patientIdentifier AS "Index_Patient_Identifier", patientName AS "Index_Patient_Name",concat(IDXContact_name,' ',IDXContact_surname) as 'IDX_Contact_fullname',IDXContact_Age,IDXContact_relationship,
						IDXContact_sex,IDXContact_priorTests,sort_order
FROM

                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group, 
									   observed_age_group.sort_order AS sort_order

                from obs o
						-- HTS CLIENTS WITH POSITIVE HIV  STATUS BY SEX AND AGE
						 INNER JOIN patient ON o.person_id = patient.patient_id
						 AND o.concept_id = 2165 AND o.value_coded = 1738
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						
						 
						 -- PATIENT LINKED TO CARE
						 AND o.person_id in (
							select distinct os.person_id
							from obs os
							where os.concept_id = 4239 and os.value_coded = 2146
							AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						 ) 

						 -- LINKED PATIENTS THAT ACCEPTED INDEXING
						  AND o.person_id in (
							select distinct os.person_id 
							from obs os
							where os.concept_id = 4759 and os.value_coded = 2146
							AND os.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
						 )
 						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS IDXClients_Status

					-- FIND THE CONCTACT FIRSTNAME ASSOCIATED WITH THE INDEX PATIENT
					LEFT JOIN (SELECT person_id,value_text as 'IDXContact_name'	FROM obs where concept_id = 4761) as contact_firstname ON IDXClients_Status.Id = contact_firstname.person_id		
     				
					 -- FIND THE CONCTACT SURNAME ASSOCIATED WITH THE INDEX PATIENT
					 LEFT JOIN (SELECT person_id,value_text as 'IDXContact_surname' FROM obs where concept_id = 4762) as contact_surname ON IDXClients_Status.Id = contact_surname.person_id									
					
			 	     -- GET THE RELATIONSHIP TYPE BETWEEN THE INDEX PATIENT AND THEIR CONTACT
					LEFT JOIN (SELECT person_id, 
						case 
							when value_coded = 4763 then 'Partner'
							ELSE 'Child' END AS 'IDXContact_relationship' 
						FROM obs where concept_id = 4768 and value_coded in (4763,4766)) as contact_relationship 
						    ON IDXClients_Status.Id = contact_relationship.person_id
					
					-- GET THE AFE OF THE  
					LEFT JOIN (SELECT person_id,value_numeric as 'IDXContact_Age' FROM obs where concept_id = 4769) as contact_age ON IDXClients_Status.Id = contact_age.person_id			
					
					-- GET THE GENDER OF THE ELICITED CONTACT
					LEFT JOIN (SELECT person_id,
					    case 
							when value_coded = 1087 then 'Male'
							 ELSE 'Female' END AS 'IDXContact_sex' 
						FROM obs where concept_id = 4770 AND value_coded in (1087,1088)) as contact_sex 
							ON IDXClients_Status.Id = contact_sex.person_id		 
					
					-- GET INFORMATION ON PRIOR HIV TESTS OF THE ELICITED CONTACT
					LEFT JOIN (SELECT person_id,
					    case 
							when value_coded = 2136 then 'Prior Tests'
						ELSE 'No Prior Tests' END as 'IDXContact_priorTests'
						FROM obs where concept_id = 4773 and value_coded in (2136,2147)) as contact_priorTest 

						ON IDXClients_Status.Id = contact_priorTest.person_id		 
				 
					ORDER BY IDXClients_Status.Age
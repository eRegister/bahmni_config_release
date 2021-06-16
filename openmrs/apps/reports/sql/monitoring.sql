select distinct Patient_Identifier,
				Patient_Name, 
				Age, 
				DOB, 
				Gender, 
				age_group, 
				Program_Status,
				regimen_name,
				encounter_date,
				follow_up,
				drug_duration,
				intake_regimen,
				ART_Start,
				Blood_drawn,
				Results_received,
				VL_result,
				Patient_received_results,
				TB_Status
from obs o
left outer join

(
	(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age,DOB, Gender, age_group, 'Initiated' AS 'Program_Status'
	FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.birthdate DOB,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group
									  

                from obs o
						-- CLIENTS NEWLY INITIATED ON ART
						  INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND (o.concept_id = 2249 

						AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						 )
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.person_id not in (
							select distinct os.person_id from obs os
							where os.concept_id = 3634 
							AND os.value_coded = 2095 
							AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
						 )	
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Newly_Initiated_ART_Clients
ORDER BY Newly_Initiated_ART_Clients.Age)

UNION

(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age,DOB, Gender, age_group, 'Seen' AS 'Program_Status'
FROM (

select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group
								  
        from obs o
								-- CLIENTS SEEN FOR ART
                                 INNER JOIN patient ON o.person_id = patient.patient_id
                                 AND (o.concept_id = 3843 AND o.value_coded = 3841 OR o.value_coded = 3842)
								 AND MONTH(o.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
								 AND YEAR(o.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
                                 AND patient.voided = 0 AND o.voided = 0
                                 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
                                 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
                                 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'

) AS Clients_Seen

WHERE Clients_Seen.Id not in (
		select distinct patient.patient_id AS Id
		from obs o
				-- CLIENTS NEWLY INITIATED ON ART
				 INNER JOIN patient ON o.person_id = patient.patient_id
				 AND (o.concept_id = 2249 
											AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
											AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						)		
				 AND patient.voided = 0 AND o.voided = 0

							)
AND Clients_Seen.Id not in (
							select distinct(o.person_id)
							from obs o
							where o.person_id in (
									-- FOLLOW UPS
										select firstquery.person_id
										from
										(
										select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
										from obs oss
													where oss.voided=0 
													and oss.concept_id=3752 
													and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
													and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
													group by oss.person_id) firstquery
										inner join (
													select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
													from obs os
													where concept_id = 3752
													and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
													group by os.person_id
													having last_ap < 0
										) secondquery
										on firstquery.person_id = secondquery.person_id
							) and o.person_id in (
									-- TOUTS
									select distinct(person_id)
									from
									(
										select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
										from obs os
										where os.concept_id=2266
										group by os.person_id
										having latest_transferout <= CAST('#endDate#' AS DATE)
									) as TOUTS
							)					
		)

AND Clients_Seen.Id not in 
					(
						select distinct(o.person_id)
						from obs o
						where o.person_id in (
								-- FOLLOW UPS
											select firstquery.person_id
											from
											(
											select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
											from obs oss
														where oss.voided=0 
														and oss.concept_id=3752 
														and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -13 MONTH)
														group by oss.person_id) firstquery
											inner join (
														select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
														from obs os
														where concept_id = 3752
														and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														group by os.person_id
														having last_ap < 0
											) secondquery
											on firstquery.person_id = secondquery.person_id
						)
						and o.person_id in (
								-- Death
											select distinct p.person_id
											from person p
											where dead = 1
											and death_date <= CAST('#endDate#' AS DATE)		
						)
					)

ORDER BY Clients_Seen.patientName)

UNION


-- INCLUDE MISSED APPOINTMENTS WITHIN 28 DAYS ACCORDING TO THE NEW PEPFAR GUIDELINE
(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name" , Age, Gender, age_group, 'MissedWithin28Days' AS 'Program_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
						-- PATIENTS WHO HAVE NOT RECEIVED ARV's WITHIN 4 WEEKS (i.e. 28 days) OF THIER LAST MISSED DRUG PICK-UP
						 inner join patient on o.person_id = patient.patient_id
						 and patient.voided = 0 AND o.voided = 0
						 and o.concept_id = 3752
						 and o.obs_id in (
								select os.obs_id
								from obs os
								where os.concept_id=3752
								and os.obs_id in (
									select observation_id
									from
										(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
										from obs oss 
											inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											and oss.value_datetime <= cast('#endDate#' as date)
										group by p.person_id) as latest_followup_obs
								)
								and os.value_datetime < cast('#endDate#' as date)
								and datediff(cast('#endDate#' as date), os.value_datetime) between 0 and 28
						 )
						 
				and o.person_id not in (
							select distinct os.person_id
							from obs os
							where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
							AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)
							
				and o.person_id not in (
							select distinct person_id
							from obs 
							where concept_id = 2249
							AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)

				and o.person_id not in (
							select distinct(o.person_id)
							from obs o
							where o.person_id in (
							-- TOUTS
									select distinct person_id
											from
											(
												select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
												from obs os
												where os.concept_id=2266
												group by os.person_id
												having latest_transferout <= CAST('#endDate#' AS DATE)
											) as TOUTS
										
											 where TOUTS.person_id not in
												 (
													 select oss.person_id
													 from obs oss
													 where concept_id = 3843
													 and CAST(oss.obs_datetime AS DATE) > latest_transferout
													 and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
												 )
						   
										)
							and o.person_id not in(
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
										AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)
										)					

						 and o.person_id not in (
									select person_id 
									from person 
									where death_date <= cast('#endDate#' as date)
									and dead = 1
						 )
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1						 
						 INNER JOIN reporting_age_group AS observed_age_group ON
						 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE 	observed_age_group.report_group_name = 'Modified_Ages'

				   AND o.person_id in (
					   				select distinct (person_id)									
									from 			
										(select os.person_id, cast(max(os.value_datetime) as date) as latest_appointment
												from obs os
												where os.concept_id=3752 
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id		
										) as app
										where latest_appointment < CAST('#endDate#' AS DATE)
										and DATEDIFF(CAST('#endDate#' AS DATE),latest_appointment) BETWEEN 0 AND 28



				   )			
				   ) AS TwentyEightDayDefaulters
				   order by TwentyEightDayDefaulters.patientName)

UNION

(SELECT Id,patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age,DOB, Gender, age_group, 'Seen_Prev_Months' AS 'Program_Status'
FROM (
(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
								   person.birthdate DOB,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group
from obs o
		-- Seen in Previous Months
		 INNER JOIN patient ON o.person_id = patient.patient_id
		 AND o.person_id in (
				 -- begin
				 select active_clients.person_id
				 from ( 
						select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_group_id)), 20) as max_obs_group_id
						from obs oss
						where oss.concept_id = 3752 and oss.voided=0
						and oss.obs_datetime < cast('#endDate#' as date)
						 group by oss.person_id
				 ) as active_clients		
				 -- Getting the obs_group_id corresponding with the latest follow_up	 
				 where latest_follow_up >= cast('#endDate#' as DATE)
				 and max_obs_group_id in (
					select obs_id from obs where obs_id = max_obs_group_id and concept_id = 3753
				 )
						
				and active_clients.person_id not in (
									select distinct os.person_id
									from obs os
									where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
									AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
									AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)
								
				and active_clients.person_id not in (
									select distinct os.person_id
									from obs os
									where concept_id = 2249
									AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
									AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)

				and active_clients.person_id not in (
									select distinct(o.person_id)
									from obs o
									where o.person_id in (
							
											select distinct person_id
													from
													(
														select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
														from obs os
														where os.concept_id=2266
														group by os.person_id
														having latest_transferout <= CAST('#endDate#' AS DATE)
													) as TOUTS
												
													 where TOUTS.person_id not in
														 (
															 select oss.person_id
															 from obs oss
															 where concept_id = 3843
															 and CAST(oss.obs_datetime AS DATE) > latest_transferout
															 and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														 )
								   
												)
									and o.person_id not in(
												select distinct os.person_id
												from obs os
												where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
												AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
												AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
									)
												)
					

									and active_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= cast('#endDate#' as date)
											and dead = 1
								 )
						 )
						 -- end
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages'	)	   
		   
) AS ARTCurrent_PrevMonths
 
ORDER BY ARTCurrent_PrevMonths.Age)
) previous
ON o.person_id = Id


left outer join
(
-- regimen
select a.person_id, 
case 
when a.value_coded = 2201 then '1c'
when a.value_coded = 2202 then '4c'
when a.value_coded = 2203 then '1d'
when a.value_coded = 2204 then '4d'
when a.value_coded = 2205 then '1e'
when a.value_coded = 2207 then '1f'
when a.value_coded = 2209 then '2d'
when a.value_coded = 2210 then '2c'
when a.value_coded = 3672 then '1g'
when a.value_coded = 3673 then '1h'
when a.value_coded = 3676 then '2g'
when a.value_coded = 3678 then '2i'
when a.value_coded = 3679 then '4e'
when a.value_coded = 3680 then '4f'
when a.value_coded = 3681 then '5a'
when a.value_coded = 3682 then '5b'
when a.value_coded = 2143 then 'Other'
when a.value_coded = 4678 THEN "1j"
when a.value_coded = 4679 THEN "1k"
when a.value_coded = 4680 THEN "1m"
when a.value_coded = 4681 THEN "1n"
when a.value_coded = 4682 THEN "1p"
when a.value_coded = 4683 THEN "1q"
when a.value_coded = 4684 THEN "4g"
when a.value_coded = 4685 THEN "4h"
when a.value_coded = 4686 THEN "4i"
when a.value_coded = 4687 THEN "4j"
when a.value_coded = 4688 THEN "4k"
when a.value_coded = 4689 THEN "2j"
when a.value_coded = 4690 THEN "2k"
when a.value_coded = 4691 THEN "2l"
when a.value_coded = 4692 THEN "2m"
when a.value_coded = 4693 THEN "2n"
when a.value_coded = 4694 THEN "2o"
when a.value_coded = 4695 THEN "2p"
when a.value_coded = 4696 THEN "5c"
when a.value_coded = 4697 THEN "5d"
when a.value_coded = 4698 THEN "5e"
when a.value_coded = 4699 THEN "5f"
when a.value_coded = 4700 THEN "5g"
when a.value_coded = 4701 THEN "5h"
when a.value_coded = 4702 THEN "6c"
when a.value_coded = 4703 THEN "6d"
when a.value_coded = 4704 THEN "6e"
when a.value_coded = 4705 THEN "4f"
when a.value_coded = 4706 THEN "3d"
when a.value_coded = 4707 THEN "3e"
when a.value_coded = 4708 THEN "3f"
when a.value_coded = 4709 THEN "3g"
when a.value_coded = 4710 THEN "3h"
else 'NewRegimen' end as regimen_name
from obs a
inner join 
		(select o.person_id,max(obs_datetime) maxdate 
		from obs o 
		where obs_datetime <= '#endDate#'
		and o.concept_id = 2250
		group by o.person_id 
		)latest 
		on latest.person_id = a.person_id
where a.concept_id = 2250 
and  a.obs_datetime = maxdate
) regimen

ON previous.Id = regimen.person_id

left outer JOIN
-- encounter date
(select o.person_id, CAST(max_observation AS DATE) as encounter_date, CAST(latest_follow_up AS DATE) as follow_up
from obs o 
inner join 
		(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_follow_up
		 from obs oss
		 where oss.concept_id = 3752 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 3752
	and  o.obs_datetime = max_observation	
	)encounter
ON previous.Id = encounter.person_id

left outer JOIN

	(SELECT person_id, 
			CASE
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 10 AND 21 THEN '2 weeks'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 28 AND 56 THEN '1 month'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 56 AND 84 THEN '2 months'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 84 AND 112 THEN '3 months'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 112 AND 140 THEN '4 months'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 140 AND 168 THEN '5 months'
				WHEN datediff(latest_follow_up, max_observation) BETWEEN 168 AND 196 THEN '6 months'
				WHEN datediff(latest_follow_up, max_observation)   >=   196   THEN '7+ months'
				ELSE 'Other supply' 
			END as drug_duration,
			max_observation
	 FROM (
			select oss.person_id, MAX(oss.obs_datetime) as max_observation, 
				   SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_follow_up,
				   SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_group_id)), 20) as max_obs_group_id
			from obs oss
			where oss.concept_id = 3752 and oss.voided=0
			and oss.obs_datetime < cast('#endDate#' as date)
			group by oss.person_id
	 ) as latest_follow_up_obs
	 -- Getting the obs_group_id corresponding with the latest follow_up	 
	 where latest_follow_up >= cast('#endDate#' as DATE)
		   and max_obs_group_id in (
			  select obs_id from obs where obs_id = max_obs_group_id and concept_id = 3753
		   )
	 ) duration ON previous.Id = duration.person_id

left outer JOIN
-- intake regimen
(
select a.person_id,case
when a.value_coded = 4714 then '1a'
when a.value_coded = 4715 then '1b'
when a.value_coded = 2201 then '1c'
when a.value_coded = 2202 then '4c'
when a.value_coded = 2203 then '1d'
when a.value_coded = 2204 then '4d'
when a.value_coded = 2205 then '1e'
when a.value_coded = 2207 then '1f'
when a.value_coded = 2209 then '2d'
when a.value_coded = 2210 then '2c'
when a.value_coded = 3672 then '1g'
when a.value_coded = 3673 then '1h'
when a.value_coded = 3676 then '2g'
when a.value_coded = 3678 then '2i'
when a.value_coded = 3679 then '4e'
when a.value_coded = 3680 then '4f'
when a.value_coded = 3681 then '5a'
when a.value_coded = 3682 then '5b'
when a.value_coded = 2143 then 'Other'
when a.value_coded = 4678 THEN "1j"
when a.value_coded = 4679 THEN "1k"
when a.value_coded = 4680 THEN "1m"
when a.value_coded = 4681 THEN "1n"
when a.value_coded = 4682 THEN "1p"
when a.value_coded = 4683 THEN "1q"
when a.value_coded = 4684 THEN "4g"
when a.value_coded = 4685 THEN "4h"
when a.value_coded = 4686 THEN "4i"
when a.value_coded = 4687 THEN "4j"
when a.value_coded = 4688 THEN "4k"
when a.value_coded = 4689 THEN "2j"
when a.value_coded = 4690 THEN "2k"
when a.value_coded = 4691 THEN "2l"
when a.value_coded = 4692 THEN "2m"
when a.value_coded = 4693 THEN "2n"
when a.value_coded = 4694 THEN "2o"
when a.value_coded = 4695 THEN "2p"
when a.value_coded = 4696 THEN "5c"
when a.value_coded = 4697 THEN "5d"
when a.value_coded = 4698 THEN "5e" 
when a.value_coded = 4699 THEN "5f"
when a.value_coded = 4700 THEN "5g"
when a.value_coded = 4701 THEN "5h"
when a.value_coded = 4702 THEN "6c"
when a.value_coded = 4703 THEN "6d"
when a.value_coded = 4704 THEN "6e"
when a.value_coded = 4705 THEN "4f"
when a.value_coded = 4706 THEN "3d"
when a.value_coded = 4707 THEN "3e"
when a.value_coded = 4708 THEN "3f"
when a.value_coded = 4709 THEN "3g"
when a.value_coded = 4710 THEN "3h"
else 'New Regimen' end as intake_regimen
	from obs a,obs b
	where a.person_id = b.person_id
	and a.concept_id = 2250
	and b.concept_id = 2397
	and a.obs_datetime = b.obs_datetime
	) intakes
	ON previous.Id = intakes.person_id
	
-- ART START	
	left outer join
	(
	select person_id,CAST(value_datetime AS DATE) as ART_Start
	from obs where concept_id = 2249
	)intake_date
	on previous.Id = intake_date.person_id

-- date blood drawn
	left outer join
	(select o.person_id,CAST(latest_blood_draw AS DATE) as Blood_drawn
	from obs o 
	inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_blood_draw
		 from obs oss
		 where oss.concept_id = 4267 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4267
	and  o.obs_datetime = max_observation	
	)blood
ON previous.Id = blood.person_id

-- date results received
left outer join
(select o.person_id,CAST(latest_results_date AS DATE) as Results_received
from obs o 
inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_results_date
		 from obs oss
		 where oss.concept_id = 4268 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4268
	and  o.obs_datetime = max_observation	
	)results_rece
ON previous.Id = results_rece.person_id

-- results
left outer join
(select o.person_id,case 
 when o.value_coded = 4263 then "Undetectale"
 when o.value_coded = 4264 then "less than 20"
 when o.value_coded = 4265 then "Greater or equal to 20"
else "other" 
end AS VL_result
from obs o
inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_results
		 from obs oss
		 where oss.concept_id = 4266 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4266
	and  o.obs_datetime = max_observation	
	)results
ON previous.Id = results.person_id

-- date results given to patient
left outer join
(select o.person_id,CAST(value_datetime AS DATE) as Patient_received_results
from obs o 
inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as latest_results_received_date
		 from obs oss
		 where oss.concept_id = 4274 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 4274
	and  o.obs_datetime = max_observation	
	)patients
ON previous.Id = patients.person_id

-- TB Screening
left outer join

(select
       o.person_id,
       case
           when value_coded = 3709 then "No Signs"
           when value_coded = 1876 then "Suspected/Probable"
           when value_coded = 3639 then "On TB Treatment"
		   when value_coded = 1876 then "TB Presumptive Case"
           else "other"
       end AS TB_Status
from obs o
inner join
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) as tb_screening_status
		 from obs oss
		 where oss.concept_id = 3710 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest
	on latest.person_id = o.person_id
	where concept_id = 3710
	and  o.obs_datetime = max_observation
	) tbresults
ON previous.Id = tbresults.person_id

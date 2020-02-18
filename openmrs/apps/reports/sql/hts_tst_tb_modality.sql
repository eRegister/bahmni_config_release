select patient_type, 
	IF(id is null, 0,SUM(IF(outcome = 'New_Pos',1,0))) as " ",
	IF(id is null, 0,SUM(IF(outcome = 'New_Neg',1,0))) as " " 
    
FROM ( select id, outcome, patient_type
		from (

	(select distinct o.person_id as id, 'New_Pos' as outcome, 'New Positive' as patient_type
				from obs o inner join person p
                on o.person_id = p.person_id and p.voided = 0 and o.person_id in (
					select person_id
					from obs
					where concept_id = 3785 
					and value_coded in (1034,1084)
					)
					inner join patient_identifier on patient_identifier.patient_id = o.person_id and patient_identifier.identifier_type = 3
					where o.concept_id = 4666 
					and value_coded = (4664)
)
UNION
(
select distinct o.person_id as id, 'New_Neg' as outcome, 'New Negative' as patient_type
				from obs o inner join person p
                on o.person_id = p.person_id and p.voided = 0 and o.person_id in (
					select person_id
							from obs
							where concept_id = 3785 
							and value_coded in (1034,1084))
							inner join patient_identifier on patient_identifier.patient_id = o.person_id and patient_identifier.identifier_type = 3
							where o.concept_id = 4666 
							and value_coded in(4665)
)
		)as tb
) AS tb1
group by patient_type 
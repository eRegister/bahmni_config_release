SELECT concat(given_name ,' ',family_name) as Client_Name, concat(firstname,' ',surname) as Contact_Name,contact_age,c_gender.contact_gender from
(
    SELECT given_name , family_name, concept_id, firstname, surname,age_set.contact_age, obs_group_id from
    (
        SELECT first_name_set.given_name, first_name_set.family_name, first_name_set.concept_id, firstname, surname, first_name_set.obs_group_id from
        (   
            select obs_id, o.person_id, given_name, family_name, concept_id, value_text as firstname, obs_group_id, o.voided  from obs o
                inner join person_name pn on o.person_id=pn.person_id and o.voided=0
                where concept_id in (4761)
            group by obs_group_id) as first_name_set 

        inner join 
        (
            select obs_id, o.person_id, given_name, family_name, concept_id, value_text as surname, obs_group_id, o.voided  from obs o
            inner join person_name pn on o.person_id=pn.person_id and o.voided=0

            where concept_id in (4762) 
            group by obs_group_id
        ) as surname_set 
                ON first_name_set.obs_group_id=surname_set.obs_group_id 
    ) as names
            
        inner join
        (
            select obs_id, o.person_id, value_numeric as contact_age, o.obs_group_id as age_obs_group_id, o.voided  
            from obs o
            inner join person_name pn on o.person_id=pn.person_id and o.voided=0
            and o.obs_group_id in (
                        select oss.obs_group_id
                        from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4769 and oss.voided=0 
            )
                
            where concept_id = 4769
            group by obs_group_id 
        ) as age_set 

    on names.obs_group_id = age_set.age_obs_group_id
) as contact_age

        inner join
            (
                select obs_id, o.person_id, IF(value_coded = 1088,'F','M') as contact_gender, o.obs_group_id as gender_obs_group_id, o.voided  
                from obs o
                inner join person_name pn on o.person_id=pn.person_id 
                and o.voided=0
                and o.value_coded in (1088,1087)
                and o.obs_group_id in (
                            select oss.obs_group_id
                            from obs oss inner join person p on oss.person_id=p.person_id and oss.concept_id = 4769 and oss.voided=0 
                )                     
                group by obs_group_id 
            ) as c_gender 
on contact_age.obs_group_id = c_gender.gender_obs_group_id
group by obs_group_id 
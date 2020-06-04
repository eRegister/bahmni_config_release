SELECT Client_Name, contact_Name, Contact_age, Gender
FROM (

SELECT cONcat(given_name ,' ',family_name) as Client_Name, cONcat(firstname,' ',surname) as contact_Name,Contact_age,c_gender.cONtact_gender as Gender from
(
    SELECT given_name , family_name, concept_id, firstname, surname,age_set.Contact_age, obs_group_id from
    (
        SELECT first_name_set.given_name, first_name_set.family_name, first_name_set.concept_id, firstname, surname, first_name_set.obs_group_id from
        (   
            select obs_id, o.person_id, given_name, family_name, concept_id, value_text as firstname, obs_group_id, o.voided  from obs o
                inner join person_name pn ON o.person_id=pn.person_id 
                AND o.voided=0
                AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
								                
                where concept_id in (4761)
            group by obs_group_id) as first_name_set 

        inner join 
        (
            select obs_id, o.person_id, given_name, family_name, concept_id, value_text as surname, obs_group_id, o.voided  from obs o
            inner join person_name pn ON o.person_id=pn.person_id 
            AND o.voided=0
            AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)								 

            where concept_id in (4762) 
            group by obs_group_id
        ) as surname_set 
                ON first_name_set.obs_group_id=surname_set.obs_group_id 
    ) as names
            
    inner join
    (
        select obs_id, o.person_id, value_numeric as Contact_age, o.obs_group_id as age_obs_group_id, o.voided  
        from obs o
        inner join person_name pn ON o.person_id=pn.person_id
        AND o.voided=0
        AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE) 
     
        AND o.obs_group_id in (
                    select oss.obs_group_id
                    from obs oss inner join person p ON oss.person_id=p.person_id 
                    AND oss.concept_id = 4769 
                    AND oss.voided=0
                    AND oss.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE) 
        )
            
        where concept_id = 4769
        group by obs_group_id 
    ) as age_set 

    ON names.obs_group_id = age_set.age_obs_group_id
) as Contact_age

inner join

(
    select obs_id, o.person_id, IF(value_coded = 1088,'F','M') as cONtact_gender, o.obs_group_id as gender_obs_group_id, o.voided  
    from obs o
    inner join person_name pn ON o.person_id=pn.person_id 
    AND o.voided=0
    AND o.value_coded in (1088,1087)
    AND o.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
    
    AND o.obs_group_id in (
                select oss.obs_group_id
                from obs oss inner join person p ON oss.person_id=p.person_id 
                AND oss.concept_id = 4769 
                AND oss.voided=0 
                AND oss.obs_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)
    )

    group by obs_group_id 
) as c_gender 

ON Contact_age.obs_group_id = c_gender.gender_obs_group_id
group by obs_group_id 
) as pivot
group by Client_Name,Contact_age,Gender
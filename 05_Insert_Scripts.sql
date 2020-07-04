Use client_db;

TRUNCATE TABLE COntact_List_Stg;
Insert into Contact_List_STg
(
title ,
first_name ,
last_name ,
company_name ,
date_of_birth ,
notes ,
street1 ,
street2,
suburb,
city ,
post_code  ,
Home_Number ,
Fax_Number ,
Work_Number ,
Mobile_Number,
Other_Number 
)
SELECT 
    Title,
    First_Name,
    Last_Name,
    IF(LOCATE('.', business, 1),
        CONCAT(UPPER(SUBSTR(business, 1, Acr_loc + 1)),
                ' ',
                INITCAP(TRIM(SUBSTR(business,
                                Acr_loc + 2,
                                LENGTH(business))))),
        INITCAP(business)) Company_Name,
    CASE
        WHEN Date_Of_Birth = '' THEN NULL
        WHEN
            (EXTRACT(YEAR FROM STR_TO_DATE(Date_of_Birth, '%m/%d/%Y')) >= EXTRACT(YEAR FROM SYSDATE()))
        THEN
            DATE_SUB(STR_TO_DATE(Date_of_Birth, '%m/%d/%Y'),
                INTERVAL 100 YEAR)
        ELSE STR_TO_DATE(Date_of_Birth, '%m/%d/%Y')
    END Date_of_Birth,
    NOtes,
    Address_Line1,
    Address_Line2,
    Suburb,
    City,
    Post_Code,
    Home_number,
    Fax_Number,
    Work_Number,
    Mobile_Number,
    Other_Number
FROM
    (SELECT 
        INITCAP(REPLACE(Title, '.', '')) AS Title,
            INITCAP(First_Name) First_Name,
            INITCAP(Last_Name) Last_Name,
            (2 * (LENGTH(business) - LENGTH(REPLACE(business, '.', '')))) AS Acr_loc,
            business,
            CLEAN_PH_NUM(Fax_Number) AS Fax_NUmber,
            CLEAN_PH_NUM(Work_NUmber) AS Work_NUmber,
            CLEAN_PH_NUM(Mobile_Number) AS Mobile_Number,
            CLEAN_PH_NUM(Home_Number) AS Home_Number,
            CLEAN_PH_NUM(Other_NUmber) AS Other_Number,
            TRIM(IF(SUBSTR(Date_of_Birth, 1, INSTR(Date_of_Birth, ' ')) = '', Date_of_Birth, SUBSTR(Date_of_Birth, 1, INSTR(Date_of_Birth, ' ')))) AS Date_of_Birth,
            INITCAP(Address_Line1) AS Address_Line1,
            INITCAP(Address_Line2) AS Address_Line2,
            INITCAP(Suburb) AS Suburb,
            INITCAP(City) AS City,
            Post_Code,
            Notes
    FROM
        contact_list) cl;

COMMIT;

Truncate table contact;

-- Assumptions
-- Notes field special character not removed as it is user field
Insert into contact (id, Title, First_Name, Last_Name,Company_Name, Date_Of_Birth,Notes)
select Contact_id, title, first_name, last_name, company_name, Date_of_birth, substr(Notes,1,255) from contact_list_stg
where Title in ('Mr', 'Mrs', 'Miss', 'Ms', 'Dr');

COMMIT;        

Truncate table address;

Insert into address (contact_id, street1, street2, suburb,city,post_code)
select contact_id, street1, street2, suburb,city,post_code from contact_list_stg;

COMMIT;

-- Assumptions taken:
-- Fax number classified under landline and hence prefixed with 09 - existing data has 09 prefix
-- Since the name field is of 64 char selecting either first/last name instead of concatenating
-- There are entries where home/work or work/mobile is same but not removing this as it is not given which type should be priorized in case of conflict
-- and also it is mentioned exported data must be consistent
-- Same reason for changing the phone definition to include 'Fax' in Type
TRUNCATE TABLE PHONE;
Insert  into Phone (contact_id, name, content, type)
select contact_id, Coalesce(First_Name,last_Name,company_name) Name_det, Mobile_number as Ph_Number, 'Mobile' as ph_Type
from contact_list_stg
where ifnull(mobile_number,'') <> ''
UNION 
select contact_id, Coalesce(First_Name,last_Name,company_name), Home_number, 'Home' as ph_Type
from contact_list_stg
where ifnull(Home_number,'') <> ''
union
select contact_id, Coalesce(company_name,First_Name,last_Name), Work_number, 'Work' as ph_Type
from contact_list_stg
where ifnull(work_number,'') <> ''
union
select contact_id, Coalesce(company_name,First_Name,last_Name), Fax_number, 'Fax' as ph_Type
from contact_list_stg
where ifnull(fax_number,'') <> ''
union
select contact_id, Coalesce(company_name,First_Name,last_Name), Other_number, 'Other' as ph_Type
from contact_list_stg
where ifnull(Other_number,'') <> ''
order by contact_id;

COMMIT;
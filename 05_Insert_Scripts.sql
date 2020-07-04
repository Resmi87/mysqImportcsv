Use client_db;

TRUNCATE TABLE contact_list_stg;
INSERT INTO contact_list_stg
(
Title,
First_Name,
Last_Name,
Company_Name,
Date_of_Birth,
Notes,
Street1,
Street2,
Suburb,
City,
Post_Code,
Home_Number,
Fax_Number,
Work_Number,
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
    Notes,
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

TRUNCATE TABLE contact;

-- Assumptions
-- Notes field special character not removed as it is user field
INSERT INTO contact (id, Title, First_Name, Last_Name,Company_Name, Date_Of_Birth,Notes)
SELECT 
    Contact_id,
    Title,
    First_Name,
    Last_Name,
    company_name,
    Date_of_birth,
    SUBSTR(Notes, 1, 255)
FROM
    contact_list_stg
WHERE
    Title IN ('Mr' , 'Mrs', 'Miss', 'Ms', 'Dr');

COMMIT;        

TRUNCATE TABLE address;

INSERT INTO address (contact_id, street1, street2, suburb,city,post_code)
SELECT 
	contact_id, 
	street1, 
	street2, 
	suburb,
	city,
	post_code 
FROM contact_list_stg;

COMMIT;

-- Assumptions taken:
-- Fax number classified under landline and hence prefixed with 09 - existing data has 09 prefix
-- Since the name field is of 64 char selecting either first/last name instead of concatenating
-- There are entries where home/work or work/mobile is same but not removing this as it is not given which type should be priorized in case of conflict
-- and also it is mentioned exported data must be consistent
-- Same reason for changing the phone definition to include 'Fax' in Type
TRUNCATE TABLE PHONE;
INSERT  INTO Phone (contact_id, name, content, type)
SELECT 
    contact_id,
    COALESCE(First_Name, last_Name, company_name) Name_det,
    Mobile_number AS Ph_Number,
    'Mobile' AS ph_Type
FROM
    contact_list_stg
WHERE
    IFNULL(mobile_number, '') <> '' 
UNION SELECT 
    contact_id,
    COALESCE(First_Name, last_Name, company_name),
    Home_number,
    'Home' AS ph_Type
FROM
    contact_list_stg
WHERE
    IFNULL(Home_number, '') <> '' 
UNION SELECT 
    contact_id,
    COALESCE(company_name, First_Name, last_Name),
    Work_number,
    'Work' AS ph_Type
FROM
    contact_list_stg
WHERE
    IFNULL(work_number, '') <> '' 
UNION SELECT 
    contact_id,
    COALESCE(company_name, First_Name, last_Name),
    Fax_number,
    'Fax' AS ph_Type
FROM
    contact_list_stg
WHERE
    IFNULL(fax_number, '') <> '' 
UNION SELECT 
    contact_id,
    COALESCE(company_name, First_Name, last_Name),
    Other_number,
    'Other' AS ph_Type
FROM
    contact_list_stg
WHERE
    IFNULL(Other_number, '') <> ''
ORDER BY contact_id;

COMMIT;
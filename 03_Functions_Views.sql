USE client_db;
DROP function IF EXISTS INITCAP;

DELIMITER $$
USE client_db$$
CREATE FUNCTION INITCAP(input VARCHAR(255))
RETURNS VARCHAR(255)
BEGIN
	DECLARE len INT;
	DECLARE i INT;
	IF TRIM(input) = '' THEN RETURN NULL;
	END IF;
	SET len   = CHAR_LENGTH(input);
	SET input = LOWER(input);
	SET i = 0;
	WHILE (i < len) DO
		IF (MID(input,i,1) = ' ' OR i = 0 OR MID(input,i,1) = '-' OR MID(input,i,1) = '''') THEN
			IF (i < len) THEN
				SET input = CONCAT(
					LEFT(input,i),
					UPPER(MID(input,i + 1,1)),
					RIGHT(input,len - i - 1)
				);
			END IF;
		END IF;
		SET i = i + 1;
	END WHILE;
	RETURN input;
END;$$

DELIMITER ;

DROP function IF EXISTS CLEAN_PH_NUM;

DELIMITER $$
USE client_db$$
CREATE FUNCTION CLEAN_PH_NUM(input VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
DECLARE PH_NUM VARCHAR(100);
IF TRIM(ifnull(input,'')) = '' THEN RETURN NULL;
Else 
 SET input= REPLACE(REPLACE(REPLACE(REPLACE(input,'-',''),' ',''),'(',''),')','');
 CASE WHEN LEFT(input,2) = '09' THEN 
	SET PH_NUM = input;
      WHEN LEFT(input,2) <> '09' AND LENGTH(input) <=7 THEN 
	SET PH_NUM = CONCAT('09',input);
      WHEN LENGTH(input) >=7 AND LEFT(input,2) = '64' THEN 
	SET PH_NUM = input;
      WHEN LENGTH(input) >=7 AND LEFT(input,2) <> '64' THEN 
	SET PH_NUM = CONCAT('64',input);
-- Assuming that prefix as 09 instead of (09), same for 64
 END CASE;
END IF;
RETURN ph_num;
END;$$

DELIMITER ;

CREATE  OR REPLACE VIEW v_contact_list_updtd AS
SELECT 'company_name,title,first_name,last_name,date_of_birth,Address_Line1,Address_Line2,suburb,city,post_code,Home_Number,Fax_Number,work_Number,Mobile_Number,Other_number,notes' as rpt_fld
FROM DUAL 
UNION
Select CONCAT('"',
            CONCAT_WS('","',
                    ifnull(company_name,''),
                    ifnull(title,''),
                    ifnull(first_name,''),
                    ifnull(last_name,''),
                    ifnull(date_of_birth,''),
                    ifnull(Address_Line1,''),
                    ifnull(Address_Line2,''),
                    ifnull(suburb,''),
                    ifnull(city,''),
                    ifnull(post_code,''),
                    ifnull(Home_Number,''),
                    ifnull(Fax_Number,''),
                    ifnull(work_Number,''),
                    ifnull(Mobile_Number,''),
                    ifnull(Other_number,''),
                    notes),
            '"') rpt_fld FROM (
SELECT 
    ct.company_name,
    ct.title,
    ct.first_name,
    ct.last_name,
	ct.date_of_birth,
    adr.street1 AS Address_Line1,
    adr.street2 AS Address_Line2,
    adr.suburb,
    adr.city,
    adr.post_code,
    ph_det.Home_Number,
    ph_det.Fax_Number,
    ph_det.work_Number,
    ph_det.Mobile_Number,
    ph_det.Other_number,
    ct.notes
FROM
    contact ct
        LEFT OUTER JOIN
    (SELECT 
        contact_id,
            MAX(home_number) AS Home_number,
            MAX(Fax_Number) AS Fax_Number,
            MAX(Work_Number) AS Work_Number,
            MAX(Mobile_Number) AS Mobile_Number,
            MAX(Other_Number) AS Other_Number
    FROM
        (SELECT 
        contact_id,
            name,
            CASE
                WHEN type = 'Home' THEN content
            END AS Home_Number,
            CASE
                WHEN type = 'Fax' THEN content
            END AS Fax_Number,
            CASE
                WHEN type = 'Work' THEN content
            END AS Work_Number,
            CASE
                WHEN type = 'Mobile' THEN content
            END AS Mobile_Number,
            CASE
                WHEN type = 'Other' THEN content
            END AS Other_Number
    FROM
        phone) ph
    GROUP BY contact_id) ph_det ON ct.id = ph_det.contact_id
        LEFT OUTER JOIN
    address adr ON ct.id = adr.contact_id
) vw;

CREATE  OR REPLACE VIEW v_report_data_Integrity AS 
SELECT 'Business,First_Name,Issue,Issue_Data' as rpt_fld
FROM DUAL
UNION
 SELECT CONCAT('"',
    CONCAT_WS('","',
            CAST(ifnull(Business,'') AS CHAR),
            CAST(ifnull(First_Name,'') AS CHAR),
            CAST(Issue AS CHAR),
            CAST(Issue_Data AS CHAR)),
            '"') as rpt_fld
FROM (SELECT 
    Company_Name AS Business,
    first_name,
    'Special char in Notes' AS Issue,
    Notes AS Issue_Data
FROM
    contact_list_stg
WHERE
    notes REGEXP '[^ -~]' 
UNION ALL 
SELECT 
    Company_Name,
    First_Name,
    'Duplicate Phone numbers' AS ISsue,
    CASE
        WHEN Home_Number = Mobile_Number THEN Home_Number
        WHEN Work_Number = Mobile_Number THEN Work_Number
    END
FROM
    contact_list_stg
WHERE
    (Home_Number = Mobile_Number
        OR Work_Number = Mobile_Number))di;
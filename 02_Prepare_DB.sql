USE client_db;

DROP TABLE IF EXISTS contact;
CREATE TABLE contact (
id INT(11) NOT NULL AUTO_INCREMENT,
title ENUM('Mr', 'Mrs', 'Miss', 'Ms', 'Dr'),
first_name VARCHAR(64),
last_name VARCHAR(64),
company_name VARCHAR(64),
date_of_birth DATETIME,
notes VARCHAR(255),
PRIMARY KEY(id)
);

DROP TABLE IF EXISTS address;
CREATE TABLE address (
id INT(11) NOT NULL AUTO_INCREMENT,
contact_id INT(11) NOT NULL,
street1 VARCHAR(100),
street2 VARCHAR(100),
suburb VARCHAR(64),
city VARCHAR(64),
post_code VARCHAR(16),
PRIMARY KEY(id)
);

DROP TABLE IF EXISTS phone;
CREATE TABLE phone (
id INT(11) NOT NULL AUTO_INCREMENT,
contact_id INT(11) NOT NULL,
name VARCHAR(64),
content VARCHAR(64),
type ENUM('Home', 'Work', 'Mobile','Fax', 'Other'),
PRIMARY KEY(id)
);

DROP TABLE IF EXISTS contact_list;
CREATE TABLE contact_list (
Business VARCHAR(100),
Title VARCHAR(100),
First_Name VARCHAR(255),
Last_Name VARCHAR(255),
Date_Of_Birth VARCHAR(40),
Address_Line1 VARCHAR(4000),
Address_Line2 VARCHAR(4000),
Suburb VARCHAR(4000),
City VARCHAR(255),
Post_Code VARCHAR(20),
Home_Number VARCHAR(100),
Fax_Number VARCHAR(100),
Work_Number VARCHAR(100),
Mobile_Number VARCHAR(100),
Other_Number VARCHAR(100),
Notes VARCHAR(4000)
);

DROP TABLE IF EXISTS contact_list_stg;
CREATE TABLE contact_list_stg (
Contact_id INT(11) NOT NULL AUTO_INCREMENT,
title VARCHAR(10),
first_name VARCHAR(64),
last_name VARCHAR(64),
company_name VARCHAR(64),
date_of_birth DATETIME,
notes VARCHAR(255),
street1 VARCHAR(100),
street2 VARCHAR(100),
suburb VARCHAR(64),
city VARCHAR(64),
post_code VARCHAR(16),
Home_Number VARCHAR(64),
Fax_Number VARCHAR(64),
Work_Number VARCHAR(64),
Mobile_Number VARCHAR(64),
Other_Number VARCHAR(64),
PRIMARY KEY(Contact_id)
);


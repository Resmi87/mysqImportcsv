DROP Database IF EXISTS client_db;
Create Database client_db;

Use client_db;

DROP USER IF EXISTS 'client_db_test'@'localhost';
CREATE USER 'client_db_test'@'localhost' IDENTIFIED BY 'client_db_test';

GRANT ALL ON client_db.* TO 'client_db_test'@'localhost';
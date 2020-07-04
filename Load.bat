echo off
setlocal enabledelayedexpansion
echo ********************* Important *************************
echo This program takes the following assumptions:
echo 1) The Source_File need to be placed in the location as specified against "secure_file_priv" in my.ini
echo 2) Please ensure that the Source_file name is contact_list.csv
echo 3) Please ensure that the root/admin user details is present in .mylogin.cnf, as the MySQL scripts are 
echo    run against root, using .mylogin.cnf
echo. 

:verify_confirm
set user_confirm=Y
set /P user_confirm= Please press enter or Y to proceed, or X to abort: 
for %%? in (X Y) do if /I "%user_confirm%"=="%%?" goto Validate_Path_File
goto :verify_confirm

:Validate_Path_File
if /I "%user_confirm%"=="X" (
set return_status=user_requested_abort
goto :exitrunningstate
)
if /I "%user_confirm%"=="Y" (
set /P Src_File_Dir= Please enter the Source file location in Double-quotes:
REM set Src_File_Dir="E:\MySQL\Uploads"
set Src_File_Name=contact_list.csv
FOR %%f IN (%Src_File_Dir%) DO (
set old=%%f
set new=!old:\=/!
echo.          
)
)
call :Setup %Src_File_Dir% %Src_File_Name% !new! goto THEEND
if "%return_status%"=="fail" (goto exitrunningstate)

:Start_Loading

if exist %log% del /f %log%
echo. > "%log%"
if exist %Data_Int% del /f %Data_Int%
if exist %Src_File_Dir%\%Upd_Data% del /f %Src_File_Dir%\%Upd_Data%
if exist %Src_File_Dir%\%Data_Int% del /f %Src_File_Dir%\%Data_Int%
if exist %Rep_Sql_cl% del /f %Rep_Sql_cl%
if "%return_status%"=="success" (Call :Validate_User)
if "%return_status%"=="success" (Call :Build_DB)
if "%return_status%"=="success" (Call :Load_Data)
if "%return_status%"=="success" (Call :Populate_Tables)
if "%return_status%"=="success" (Call :Run_Reports)

goto:eof

:Validate_User
echo Please enter the sysdba/root user: 
set /P admin_user= 
if /I "X%admin_user%"=="X" goto :Validate_User
rem call :test_conn
goto :eof

:Build_DB
echo Preparing DB...
call :run_MySQL %admin_user% %sql_file_dir% 01_Create_DB.sql
call :run_MySQL %admin_user% %sql_file_dir% 02_Prepare_DB.sql %db_name%
call :run_MySQL %admin_user% %sql_file_dir% 03_Functions_Views.sql %db_name%
goto:eof

:Load_Data
echo Loading Source Data...
call :run_MySQL_Import %admin_user% %db_name% !import_folder! %Src_File_Name%
goto:eof

:Populate_Tables
echo Populating Main Tables...
call :run_MySQL %admin_user% %sql_file_dir% 05_Insert_Scripts.sql %db_name%
goto:eof

:Run_Reports
echo Generating Reports...
REM call :run_MySQL_Rep %admin_user% %sql_file_dir% 06_Report_Data_Integrity.sql %db_name%
REM call :run_MySQL_Rep %admin_user% %sql_file_dir% 07_Report_Contact_List_Upd.sql %db_name%
call :Generate_Rep !import_folder! %Upd_Data% %Vw_Rpt_cl% %Rep_Sql_cl%
call :Generate_Rep !import_folder! %Data_Int% %Vw_Rpt_di% %Rep_Sql_di%
call :run_MySQL %admin_user% %sql_file_dir% %Rep_Sql_cl% %db_name%
call :run_MySQL %admin_user% %sql_file_dir% %Rep_Sql_di% %db_name%
if "%return_status%"=="success" echo Reports: %Data_Int% and %Upd_Data% are available in %Src_File_Dir%
goto:eof

:Generate_Rep
echo Generating Report %4 >> "%log%" 2>&1
echo select rpt_fld into OUTFILE '%1/%2' from %3> %4
:exit_Generate_Rep
goto:eof

:run_MySQL_Rep
echo came to mysql_Rep >> "%log%" 2>&1
type params.sql 07_Report_Contact_List_Upd.sql | MySQL --login-path=%1 %4 < %2\%3
:exit_run_MySQL_Rep
goto:eof

:run_MySQL
echo Running file %3 >> "%log%" 2>&1
MySQL --login-path=%1 %4 < %2\%3
set return_status=success
:exit_run_MySQL
goto:eof

:run_MySQL_Import
echo Loading Source data >> "%log%" 2>&1
mysqlimport --login-path=%1 %2 --delete --ignore-lines=1 --lines-terminated-by="\r\n" --fields-terminated-by="," --fields-enclosed-by="\"" "%3\%4"
:exit_run_MySQL_Import
goto:eof

:test_conn
echo came to test_conn
MySQL --login-path=%admin_user% > "%log%" 2>&1
if not %errorlevel%==0 (
set return_status=fail
goto exitrunningstate
)
set return_status=success
echo MySQL connection failure
:exit_test_conn
goto:eof

:Setup
set db_name=client_db
set sql_file_dir=%cd%
set log=Log_file.log
set import_folder=%~3
set Rep_Sql_cl=Report_contact_list.sql
set Vw_Rpt_cl=v_contact_list_updtd
set Upd_Data=Updated_Contact_List.csv
set Rep_Sql_di=Report_data_integrity.sql
set Vw_Rpt_di=v_report_data_Integrity
set Data_Int=Data_Integrity.csv
REM echo SET @Upd_Data='!import_folder!/Updated_Contact_List.csv' > params.sql
call :check_exist %~1\%2
:exit_Setup
goto:eof

:check_exist
if not exist %~1 (
	set return_status=fail
	echo error: Unable to find file in : ^(%~1^)
	goto exit_check_exist
	)
	echo Source File exists ok: %~1
	set return_status=success
:exit_check_exist
goto:eof

:exitrunningstate
set exit_status=1
if /I %return_status%==user_requested_abort (
title Aborted
echo User requested exit
set exit_status=1
)
exit /b %exit_status%

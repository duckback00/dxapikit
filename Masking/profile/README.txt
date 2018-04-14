# Filename: README.txt
#
# API_DEMO - Profiling Many Database Environments
#
# Description: Demo script for profile multiple databases at a time
#              using the new Delphix Masking 5.2 APIs
#
# Usage:
# 1.) [ edit profile.sh and change Masking Engine connection parameters ]
# 2.) Either update the hard-coded connections or provide a comma delimited
#     list of database connections, must match provided format!
# 3.) Or use the connections provided with an account that has privileges
#     to see/select other schemas and use the ALL argument.
#     ALL option is currently for Oracle connections ONLY.
#     This option requires sqlplus be installed and found in path.
#     Also: See minimum account privileges required at the end of this file.
#
# [shell_prompt$]  ./profile.sh
#
# [shell_prompt$]  ./profile.sh profile_connections.csv
#
# NOTE: ALL option is for Oracle connections ONLY and requires sqlplus
#       Change allcons.sh PATH variable for sqlplus client path 
#
# [shell_prompt$]  ./profile.sh ALL                  
#
# [shell_prompt$]  ./profile.sh profile_connections.csv ALL  
#


################################################################
# Files ...

profile.sh              # Main script to profile one or many environments ...
batch.sh		# Batch Job Script for executing parallel jobs or single job ...
procons.sh              # Script for CSV filename command line option, converts CSV data into JSON string 
allcons.sh              # Script for ALL command line option that generates a list of "OPEN" schemas/databases
                        # be sure to change PATH variable so sqlplus client can be executed
report.sh               # Script to generate Report HTML Files from the db conn results, json.out file
html			# Directory for HTML Reports and CSV results
htmo/images/            # Images for Delphix Logo's and/or Customer Logo's
README.txt              # This file ...
profile_connections.csv		# Sample list of saved CSV formatted database connections
profile_connections.csv_orig	
Profiling_Sources_v4.pptx	# WIP - DRAFT Presentation ...


################################################################
# Create a zip file of required files/folder structure ...

zip -r masking_api_demo.zip html README.txt *.sh *.csv*


################################################################
# On source Unix/Linux/Mac systems ...

1.) Verify jq is installed ...

jq --version
jq version 1.3

If not, install it ...

sudo apt-get install jq
... or ...
sudo yum install jq


2.) cd /[path_to_script_directory]/API_DEMO ...

vi profile.sh
[ change any *parameters ]
  [ change JSON connection string data ]
... or ...
  [ use Spreadsheet .csv front end for connection string data ... ]
  [ From Excell, MUST SAVE using Windows Comma Seperated (.csv) format ]
[ save and exit ]

* Parameters to change for your configuration;

   #
   # Delphix Masking Engine ...
   #
   DMURL="http://172.16.160.195:8282/masking/api"
   DMUSER="Axistech"
   DMPASS="Axis_123"

   PARALLEL=0 		# 0 or 1 = Single Job for All Connections ...
   PARALLEL=4     	# Number of Parallel Jobs, connections per job will be automatically computed ...


3.) Run the Profile API Script ...

#
# for hard coded connections ...
#
./profile.sh

#
# for Spreadsheet CSV data connections ...
#
# ./profile.sh [filename.csv]

./profile.sh profile_connections.csv


#
# The ALL option is for Oracle ONLY and REQUIRES sqlplus on local computer
# See allcons.sh PATH variable setting at top of file
#
# Also: See minimum account privileges required at the end of this file.
#

#
# to use the hard-coded account to read all schemas/tables the account has privileges to see/select ...
#
./profile.sh ALL

#
# or use the CSV data provided accounts to read all schemas/tables the account has privileges to see/select ...
#

./profile.sh profile_connections.csv ALL


4.) Display Results ...

Open Web Browser and open the URL ...

file:///[full_path_to_directory]/API_DEMO/html/report.html


################################################################
# Spreadsheet CSV File Structure ...

databaseType,host,port,sid,instanceName,databaseName,schemaName,username,password,jdbc,profileSetName,theEnd
ORACLE,172.16.160.133,1521,VBITT,,,DELPHIXDB,DELPHIXDB,delphixdb,,Financial,theEnd
ORACLE,172.16.160.133,1521,VBITT,,,DELPHIXDB,DELPHIXDB,delphixdb,,HIPAA,theEnd
ORACLE,172.16.160.133,1521,orcl,,,DELPHIXDB,DELPHIXDB,delphixdb,,Financial,theEnd
ORACLE,172.16.160.133,1521,orcl,,,DELPHIXDB,DELPHIXDB,delphixdb,,HIPAA,theEnd


################################################################
# Oracle Database Account Minimum Privileges for ALL option ...

-----------------------------------------------------
-- Minimum Required Privileges for Profile Options --
-----------------------------------------------------
SQL> 
-- drop user profiler cascade;
CREATE USER profiler IDENTIFIED BY profiler00;
grant create session to profiler; 
grant select any dictionary to profiler;

-- 
-- Grant select on any table ...
-- (not recommended)
--
-- grant select any table to profiler;

--
-- ... or limit select grants on specific accounts tables ...
-- (recommended)
--
set serveroutput on
declare
begin
for j in (select username from dba_users where account_status='OPEN' and username not in ('ANONYMOUS','APEX_030200','APEX_PUBLIC_USER','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDDATA','MDSYS','MGMT_VIEW','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','OWBSYS_AUDIT','SI_INFORMTN_SCHEMA','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','SYS','SYSMAN','SYSTEM','WMSYS','XDB','XS$NULL')) loop
   DBMS_OUTPUT.PUT_LINE('Schema '||j.username);
   for i in (select owner, object_name from all_objects where object_type='TABLE' and owner=j.username) LOOP
      execute immediate 'grant select on '||i.owner||'.'||i.object_name||' to PROFILER';
   end loop;
 end loop;
end;
/
--
-- End of Grants for Profiling Account ...
--



*** End of README.txt ***


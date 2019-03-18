#!/bin/bash
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2019 by Delphix. All rights reserved.
#
# Program Name : sample.sh
# Description  : Simple DXM-Toolkit Example
# Author       : Alan Bitterman
# Created      : 2019-03-15
# Version      : v1.0
#
# Requirements :
#  1.) dxmc executable from dxm-toolkit 
#  2.) jq command line libraries
#  3.) Change values below as required
#
# Usage:
# ./oracle_sample.sh 
#   [meta_data_file]            # 1 Column Header Name, Domain Name and Algorithm mapping file
#      [connection_str_file]    # 2 Connection String file ...
#         [YES, NO]             # 3 Run Masking Job: YES or NO
#
# ./oracle_sample.sh [meta_data_file] [connection_str_file] [YES, NO]       
#
# Samples:
# ./oracle_sample.sh ora_mask.txt conn.txt NO
#
#
# Sample Meta Data File ...
#
#[table_name].[column_name],[domain_name],[algorithm_name],[isProfileWritable],[date_format]
#                                                           Auto=true           dd-MMM-yy
#                                                           User=false          yyyy-MM-dd
#EMPLOYEES.EMPLOYEE_ID
#EMPLOYEES.FIRST_NAME,FIRST_NAME,FirstNameLookup,Auto
#EMPLOYEES.LAST_NAME,LAST_NAME,LastNameLookup,Auto
#EMPLOYEES.DEPT_NAME
#EMPLOYEES.CITY,CITY,USCitiesLookup,User
#
# Note: 5th value is for date format for respective date algorithms ...
#PATIENT.DOB,DOB,DateShiftDiscrete,User,dd-MMM-yy
#
# Sample Connection String File ...
## Note: connNo MUST BE 1, profileSetName not required
#
#=== begin of file ===
#[
#{
#  "username": "DELPHIXDB",
#  "password": "delphixdb",
#  "databaseType": "ORACLE",
#  "host": "172.16.160.133",
#  "port": 1521,
#  "schemaName": "DELPHIXDB",
#  "profileSetName": "HIPAA",
#  "connNo": 1,
#  "sid": "orcl"
#}
#]
#=== end of file ===
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

#
# DDDP Connection ... 
#
DE="de2"
DMIP="172.16.160.195"
#DMIP="10.0.1.10"
DMUSER="Admin"
DMPASS="Admin-12"
APP="dxmc_app"
ENV="dxmc_env"

#
# Other Object Names ...
#
CNAME="Conn3"
RSNAME="RuleSet3"
MASKNAME="MaskingJob3"

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Command Line Arguments ...
#
M_SOURCE=${1}                   # Source Meta Data File
M_CONN_STR=${2}                 # Connection String File
M_RUN_JOB=${3}                  # Run Masking Job

if [[ "${M_SOURCE}" == "" ]] || [[ "${M_CONN_STR}" == "" ]]
then
   echo "Error Invalid Input:  ./oracle_sample.sh [meta_data_file] [connection_str_file] [YES, NO] "
   echo "Please re-enter command line arguments, Exiting ..."
   exit 1
fi

########################################################
## Add Engine Configuration ...

#dxmc engine list 
RESULTS=`dxmc engine list --format json`
CHK=`echo "$RESULTS" | jq -r  '.[] | select(."Engine name"=="'${DE}'") '`
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc engine add --engine ${DE} --ip ${DMIP} --username ${DMUSER} --password ${DMPASS} --default Y`
   echo "${RESULTS}"
else
   echo "Engine \"${DE}\" Already Exists ..."  #"${CHK}"
fi

########################################################
## Add Application ...
 
RESULTS=`dxmc application list --engine ${DE} --format json`
#echo "${RESULTS}"
CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Application name"=="'${APP}'" and ."Engine name"=="'${DE}'") '`
#{ "Application name": "profile_app", "Engine name": "de" }
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc application add --appname ${APP} --engine ${DE}`
   echo "${RESULTS}"
   #Application ${APP} added
else
   echo "Application \"${APP}\" Already Exists ..."
fi   

########################################################
## Add Environment ...
 
RESULTS=`dxmc environment list --engine ${DE} --format json`
#echo "${RESULTS}"
CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Environment name"=="'${ENV}'" and ."Application name"=="'${APP}'" and ."Engine name"=="'${DE}'") '`
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc environment add --envname ${ENV} --appname ${APP} --purpose MASK --engine ${DE}`
   echo "${RESULTS}"
   #Environment ${ENV} added
else
   echo "Environment \"${ENV}\" Already Exists ..."
fi   

########################################################
## Delete All Connectors in Environment ... 
 
RESULTS=`dxmc connector list --envname ${ENV} --engine ${DE} --format json`
#echo "|${RESULTS}|"
if [[ ! "${RESULTS}" =~ "No connectors found" ]]
then
   CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Environment name"=="'${ENV}'" and ."Engine name"=="'${DE}'") | ."Connector name"'`
   #echo "${CHK}"
   while read line
   do
      echo "|${line}|"
      echo "dxmc connector delete --connectorname ${line} --envname ${ENV} --engine ${DE}"
      CMD="dxmc connector delete --connectorname ${line} --envname ${ENV} --engine ${DE}"
      RESULTS=`${CMD}`
      echo "${RESULTS}"
   done <<< "${CHK}"
fi

########################################################
## Create Connection String ...

echo "Processing Connection String ..."
CONN=`cat ${M_CONN_STR}`
#echo "${CONN}"

j=1
CONN0=`echo "${CONN}" | jq --raw-output ".[] | select (.connNo == ${j})"`
#echo "$CONN0" | jq -r "."

#########################################################
## Process Provided Connectors ...

# Append connection number to connector name ...
CNAME="${CNAME}_${j}"

USR=`echo "${CONN0}" | jq --raw-output ".username"`
PWD=`echo "${CONN0}" | jq --raw-output ".password"`
#
# If Password is Encrypted, put Decrypt code here ...
#

DBT=`echo "${CONN0}" | jq --raw-output ".databaseType"`
ZTMP=`echo "${CONN0}" | jq --raw-output ".host | select (.!=null)"`
if [[ "${ZTMP}" != "" ]]
then
   HOST=`echo "${CONN0}" | jq --raw-output ".host"`
else
   HOST=""
fi
#echo "HOST: |${HOST}|"
PORT=`echo "${CONN0}" | jq --raw-output ".port"`
SCHEMA=`echo "${CONN0}" | jq --raw-output ".schemaName"`
SID=`echo "${CONN0}" | jq --raw-output ".sid"`
JDBC=`echo "${CONN0}" | jq --raw-output ".jdbc"`
DBNAME=`echo "${CONN0}" | jq --raw-output ".databaseName"`
INSTANCE=`echo "${CONN0}" | jq --raw-output ".instanceName"`

#USR="delphixdb"
USR=`echo "${USR}" | tr '[:lower:]' '[:upper:]'`
#PWD="delphixdb"
#DBT="ORACLE"
DBT=`echo "${DBT}" | tr '[:upper:]' '[:lower:]'`
#HOST="172.16.160.133"
#PORT="1521"
#SCHEMA="delphixdb"
SCHEMA=`echo "${SCHEMA}" | tr '[:lower:]' '[:upper:]'`
#SID="orcl"

########################################################
## Add Database Connector ...
 
###STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"host\": \"${HOST}\", \"password\": \"${PWD}\", \"port\": ${PORT}, \"sid\": \"${SID}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }" "${DMURL}/database-connectors"`

echo "Adding Database Connector ${CNAME} ..."
RESULTS=`dxmc connector list --envname ${ENV} --engine ${DE} --format json`
#echo "${RESULTS}"
if [[ "${RESULTS}" =~ "No connectors found" ]]
then
   CMD="dxmc connector add --connectorname ${CNAME} --envname ${ENV} --connectortype ${DBT} --host ${HOST} --port ${PORT} --username ${USR} --password ${PWD} --schemaname ${SCHEMA} --sid ${SID} --engine ${DE}"
   RESULTS=`${CMD}`
   echo "${RESULTS}"
fi

########################################################
## Test Connector ...

echo "Testing Connector ${CNAME} ..."
RESULTS=`dxmc connector test --envname ${ENV} --engine ${DE}  --connectorname ${CNAME}  --format json`
echo "${RESULTS}"
if [[ ! "${RESULTS}" =~ "succeeded" ]]
then
   echo "Error: Connector Test was not Successful, please validate and try again. Exiting ..."
   exit 1
fi

########################################################
## Fetch all tables ...

echo "Fetching Connector Tables ..."
TABLES=`dxmc connector fetch_meta --envname ${ENV} --connectorname ${CNAME} --engine ${DE} --format json`
echo "${TABLES}"

#
# Optional: Write Desired Tablenames to a CSV File ...
#

########################################################
## Add RuleSet ...

RSNAME="${RSNAME}_${j}"
echo "Adding Rule Set ${RSNAME} ..."
RESULTS=`dxmc ruleset add --rulesetname ${RSNAME} --connectorname ${CNAME} --envname ${ENV} --engine ${DE}`
echo "${RESULTS}"

# A Few Methods to Adding Tables to Rule Set ...
# 1.) Add Individual Tables with Hard Coded Values
# 2.) Use the connector fetch_meta command to get a complete list of tables, write values to .csv file
# 3.) Use CSV file to load tables ...
# 4.) Reads another formatted CSV file to load the table names (and algorithms)

#
# 1.) Add Individual Tables ...
#
#RESULTS=`dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname EMPLOYEES`
#echo "${RESULTS}"

#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname MEDICAL_RECORDS
#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname PATIENT
#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname PATIENT_DETAILS

#
# 2.) & 3.) Batch load meta data via CSV file created earlier or by user ...
#
#cat tbl.csv
## tablename, custom_sql, where_clause, having_clause, key_column
#EMP,,,,
#DEPT,,,,
#SALGRADE,,,,
#TEST,,,,
#...

#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --inputfile tbl.csv

#
# OR 4.) ...
#
#########################################################
## Get List for Tables from Source File ...

M_TBLS=`grep -v '^#' ${M_SOURCE} | cut -d. -f1 | sort -u`
echo "Tables from ${M_SOURCE}: "
echo "${M_TBLS}"

#
# add code here if you want to validated table list ...
#

########################################################
## Loop thru Tables and add to Rule Set ...

while read tbname
do
   #echo "... $tbname "
   RESULTS=`dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname ${tbname}`
   echo "${RESULTS}"
done <<< "${M_TBLS}"

#########################################################
## List Rule Set Meta Data ...

echo "RuleSet Metadata ..."
RESULTS=`dxmc ruleset listmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --format json`
echo "${RESULTS}"

#echo "Column List before assigning Algorithms ..."
#RESULTS=`dxmc column list --rulesetname ${RSNAME} --envname ${ENV} --format json`
#echo "${RESULTS}"

#########################################################
## Algorithm Logic

echo "Adding Algorithms ..."

# A Few methods for assigning Algorithms ...
# 1.) Manual Assignment/Hard Coded 
# 2.) Read from a CSV file 

#
# 1. Manual Assignment/Hard Coded Algorithms ...
#
#RESULTS=`dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname FIRST_NAME --algname FirstNameLookup --domainname FIRST_NAME`
#echo "${RESULTS}"

#RESULTS=`dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname LAST_NAME --algname LastNameLookup --domainname LAST_NAME`
#echo "${RESULTS}"

#
# 2.) Read from CSV file ...
#
#  Loop through each line in th ${M_SOURCE} file and when
#  field name match is found, update the domain/algorithm
#
# Update Inventory Field Values for Masking ...
#
TAB2_PREV=""
let k=1
while read line2
do
   echo "---------------------------------------------------"
   echo "Processing $line2 ... "
   #
   # Check for comment lines ...
   #
   C1=`echo ${line2:0:1}`
   if [[ "${C1}" == "#" ]]
   then
      printf "Comment Line Skipping.\n"
   else
      #
      # Parse Table_Name.Column_Name Data ...
      #
      FQN2=`echo $line2 | awk -F"," '{ print $1 }'`
      NAM2=`echo "${FQN2}" | cut -d. -f2`
      TAB2=`echo "${FQN2}" | cut -d. -f1`
      #echo "Table_Name.Column_Name: ${TAB2}.${NAM2}"

      VAL2=`echo $line2 | awk -F"," '{ print $2 }'`
      VAL3=`echo $line2 | awk -F"," '{ print $3 }'`
      VAL4=`echo $line2 | awk -F"," '{ print $4 }'`
      VAL5=`echo $line2 | awk -F"," '{ print $5 }'`

      #
      # Have User Input and valid column meta data id ...
      #
      if [[ "${VAL2}" != "" ]] && [[ "${TAB2}" != "" ]]
      then
         echo "Updating Domain and Algorithm for ${TAB2}.${NAM2} with ${VAL3} ..."
#   \"algorithmName\": \"${VAL3}\",
#   \"domainName\": \"${VAL2}\"

#         if [[ "${VAL2}" == "DOB" ]]
#         then
#            JSON="${JSON},
#   \"dateFormat\": \"${VAL5}\"
#"
#         fi

#         VTMP4="true"
#         if [[ "${VAL4}" == "User" ]]
#         then
#            VTMP4="false"
#         fi
#         JSON="${JSON},
#   \"isProfilerWritable\": ${VTMP4}
#}"

         #echo "dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname ${NAM2} --algname ${VAL3} --domainname ${VAL2}"
         RESULTS=`dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname ${NAM2} --algname ${VAL3} --domainname ${VAL2}`
         echo "${RESULTS}"

         ## {"errorMessage":"Missing required field 'dateFormat'"}
         #ERR_CHK=`echo "${RESULTS}" | jq -r ".errorMessage | select (.!=null) "`
         #if [[ "${ERR_CHK}" != "" ]]
         #then
         #   echo "ERROR: see above message, exiting ..."
         #   exit 1
         #fi

      fi        # end if VAL2 != ""
   fi           # end if comment line
   #
   # Reset/Set loop variables ...
   #
   FQN2=""
   NAM2=""
   TAB2=""
   VAL2=""
   VAL3=""
   VAL4=""
   VAL5=""
   k=$((k+1))

done < ${M_SOURCE}

########################################################
## Rule Set Column Algorithm List ...

echo "Column List ..."
RESULTS=`dxmc column list --rulesetname ${RSNAME} --envname ${ENV} --format json`
echo "${RESULTS}"

########################################################
## Create Masking Job ...

MASKNAME="${MASKNAME}_${j}"
echo "Create Masking Job ${MASKNAME} ..."
RESULTS=`dxmc job add --jobname ${MASKNAME} --envname ${ENV} --rulesetname ${RSNAME}`
echo "${RESULTS}"

#echo "List Masking Jobs ..."
#RESULTS=`dxmc job list --format json`
#echo "${RESULTS}"

########################################################
## Run Masking Job ...

if [[ "${M_RUN_JOB}" == "YES" ]]
then
   echo "Execute Masking Job ${MASKNAME} ..."
   RESULTS=`dxmc job start --jobname ${MASKNAME} --envname ${ENV}`
   echo "${RESULTS}"
fi

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0

#!/bin/bash
#######################################################################
# Filename: agile_oracle.sh
# Version: v1.0
# Date: 2018-12-14
# Last Updated: 2018-12-14 Bitt...
# Author: Alan Bitterman
#
# Description: Demo script for masking Oracle Database 
#              using the new Delphix Masking 5.2 APIs
#
# Arguments:
#
#./agile_oracle.sh 
#   [meta_data_file]		# 1 Column Header Name, Domain Name and Algorithm mapping file
#      [connection_str_file]   	# 2 Connection String file ...
#         [YES, NO]             # 3 Run Masking Job: YES or NO
#
# Usage:  
# ./agile_oracle.sh ora_mask.txt conn.txt YES
# ./agile_oracle.sh ora_mask.txt conn.txt NO
# ./agile_oracle.sh patient.txt conn.txt YES
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
#########################################################
#
# Debug ...
#
#set -x 

SHOW_JSON="NO"

#########################################################
## Delphix Masking Parameter Initialization

DMIP=172.16.160.195
DMPORT=8282
DMUSER="Admin"
DMPASS="Admin-12"
DMURL="http://${DMIP}:${DMPORT}/masking/api"
DELAYTIMESEC=10

M_APP="ora_app" 		# Masking Application Name ...
M_ENV="ora_env"			# Transient Masking Environment Name ...

##DT=`date '+%Y%m%d%H%M%S'`
DT=`date '+%m%d%H%M%S'`
M_RULE_SET="RS_${DT}"           #
M_MASK_NAME="Mask_${DT}"        #
M_CONN="Conn_${DT}"         	# Transient Masking Oracle Connetor Name ...

#########################################################
##        NO CHANGES REQUIED BELOW THIS LINE           ##
#########################################################

#
# Command Line Arguments ...
#
M_SOURCE=${1}			# Source Meta Data File 
M_CONN_STR=${2}  		# Connection String File 
M_RUN_JOB=${3}			# Run Masking Job

######################################################

echo "Source: ${M_SOURCE}"
echo "Application: ${M_APP}"
echo "Environment: ${M_ENV}"
echo "Connection String File: ${M_CONN_STR}"
echo "Connector: ${M_CONN}"
echo "Rule Set Name: ${M_RULE_SET}"
echo "Masking Job Name: ${M_MASK_NAME}"
echo "Run Masking Job: ${M_RUN_JOB}"

#########################################################
## Data Pre-Processing ...
#########################################################

# ...

#########################################################
## Create Masking Objects via API ... 
#########################################################

#########################################################
## Authentication ...

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#########################################################
## Get Application ...

STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/applications"`
#echo "${STATUS}"

## Create Application ...
APPNAME=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.applicationName == \"${M_APP}\") | .applicationName"`
if [[ "${M_APP}" != "${APPNAME}" ]]
then
   STATUS=`curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: ${KEY}" -d "{ \"applicationName\": \"${M_APP}\" }" "${DMURL}/applications"`
   #echo "${STATUS}" | jq "."
fi
echo "Application Name: ${M_APP}"

#########################################################
## Get Environment ...

STATUS=`curl -s -X GET --header 'Accept: application/json' --header "Authorization: ${KEY}" "${DMURL}/environments"`
#echo "${STATUS}" | jq "."

## Create Environment ...
ENVID=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.application == \"${M_APP}\" and .environmentName == \"${M_ENV}\") | .environmentId"`
if [[ "${ENVID}" == "" ]]
then
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"environmentName\": \"${M_ENV}\", \"application\": \"${M_APP}\", \"purpose\": \"MASK\" }" "${DMURL}/environments"`
   #echo "${STATUS}" | jq "."
   ENVID=`echo "${STATUS}" | jq --raw-output ". | select (.application == \"${M_APP}\" and .environmentName == \"${M_ENV}\") | .environmentId"`
fi
echo "Environment Name: ${M_ENV}"
echo "Environment Id: ${ENVID}"

#########################################################
## Get Environment Connectors ...

STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors"`
#echo ${STATUS} | jq "."
DELDB=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentId == ${ENVID}) | .databaseConnectorId "`
#echo "Delete Conn Ids: ${DELDB}"

## Delete all existing connectors ...
if [[ "${DELDB}" != "" ]]
then
while read TMPID
do
   #echo "$j ... $TMPID "
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${TMPID}"`
   #echo "${STATUS}" | jq "."
   echo "Removing previous connection id ${TMPID}"
done <<< "${DELDB}"
fi

#########################################################
## Get Rule Set ...

# Connection delete is cascaded -> rule sets -> masking jobs 
if [[ "1" == "0" ]]
then

STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-rulesets"`
#echo "${STATUS}" | jq "."
DELRS=`echo "${STATUS}" | jq --raw-output ".responseList[] | select (.environmentId == ${ENVID}) | .databaseRulesetId"`
#echo "Delete Rule Set Ids: ${DELRS}"

## Delete all existing rule sets ...
if [[ "${DELRS}" != "" ]]
then
while read TMPID
do
   #echo ".. $TMPID "
   STATUS=`curl -s -X DELETE --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-rulesets/${TMPID}"`
   #echo "${STATUS}" | jq "."
   echo "Removing previous rule set id ${TMPID}"
done <<< "${DELRS}"
fi

fi	# end if "1" == "0"

#########################################################
## Create Connection String ...

echo "Processing Connection String ..."
CONN=`cat ${M_CONN_STR}`
#echo "${CONN}"

j=1
CONN0=`echo "${CONN}" | jq --raw-output ".[] | select (.connNo == ${j})"`
#echo "$CONN0" | jq -r "."

#########################################################
## Process Provided Connectors ...

CNAME="${M_CONN}${j}"

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

CONN_STR=""      # For Reporting Purposes ONLY ...

#
# Supported Databases ...
#
if [[ "${DBT}" == "ORACLE" ]]
then
   #########################################################
   ## Create Oracle Connector ...
    
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"connectorName\": \"${CNAME}\", \"databaseType\": \"${DBT}\", \"environmentId\": ${ENVID}, \"host\": \"${HOST}\", \"password\": \"${PWD}\", \"port\": ${PORT}, \"sid\": \"${SID}\", \"username\": \"${USR}\", \"schemaName\" : \"${SCHEMA}\" }" "${DMURL}/database-connectors"`
   #echo ${STATUS} | jq "."
   DBID=`echo "${STATUS}" | jq --raw-output '.databaseConnectorId'`
   echo "Connector Id: ${DBID}"
   CONN_STR="${DBT} ${HOST}:${PORT}:${SID}"
else
   #
   # Not Supported Yet ...
   #
   echo "Error: Database ${DBT} Not Yet supported in this script, exiting ..."
   exit 1
fi
#echo "DEBUG: ${CONN_STR} "

#########################################################
## Test Connector ...
    
STATUS=`curl -s -X POST --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${DBID}/test"`
CONN_RESULTS=`echo "${STATUS}" | jq --raw-output ".response"`
if [[ "${CONN_RESULTS}" != "Connection Succeeded" ]]
then
   echo "Error: Connection ${CNAME} not valid for ${DBID} ... ${CONN_RESULTS}"
   echo "Please verify parameters and try again, exiting ..."
   exit 1
fi

#
# Have a valid database connect, let's proceed ...
#
echo "${USR} ${CONN_RESULTS}"

#########################################################
## Define Rule Set ...
          
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"rulesetName\": \"${M_RULE_SET}${j}\", \"databaseConnectorId\": ${DBID} }" "${DMURL}/database-rulesets"`
#echo ${STATUS} | jq "."
RSID=`echo "${STATUS}" | jq --raw-output ".databaseRulesetId"`
echo "Rule Set Id: ${RSID}"

#########################################################
## Get List for Tables from Source File ...

M_TBLS=`grep -v '^#' ${M_SOURCE} | cut -d. -f1 | sort -u`
echo "Tables from ${M_SOURCE}: "
echo "${M_TBLS}"

#
# only if you want to validated table list ...
#
M_VALID_TBL="NO"

if [[ "${M_VALID_TBL}" == "YES" ]]
then
   TABLES=""
   STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/database-connectors/${DBID}/fetch"`
   #echo ${STATUS} | jq "."
   TABLES=`echo "${STATUS}" | jq --raw-output ".[]"`
   #echo "Tables: ${TABLES}"

   #
   # Proceed iff schema contains or username has privileges to see  tables ...
   #
   if [[ "${TABLES}" != "" ]]
   then
      # 
      # Optional: Verify Table Names Exist ... 
      # if error, could be wrong connector schema, table name missing or misspelled
      #
      FOUND="YES"        
      while read tbl 
      do
         CHK="NO"
         while read tbname
         do
            if [[ "${tbl}" == "${tbname}" ]]
            then 
               CHK="YES"
            fi
         done <<< "${TABLES}"
         if [[ "${CHK}" == "NO" ]]
         then 
            FOUND="NO"
         fi 
      done <<< "${M_TBLS}"
      #
      # All Tables Found ???
      #
      if [[ "${FOUND}" == "NO" ]]
      then
         echo "Not All Table Names found in ${M_SOURCE}, please verify. Exiting ..."
         exit 1
      fi
   fi   # end if $TABLES ...

fi      # end if M_VALID_TBL ...

#
# Loop thru Tables and add to Rule Set ...
#
let k=0
while read tbname
do
   let k=k+1
   #echo "$k ... $tbname "
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"tableName\": \"${tbname}\", \"rulesetId\": ${RSID} }" "${DMURL}/table-metadata"`
   #echo ${STATUS} | jq "."
done <<< "${M_TBLS}"

#########################################################
## Logic

#
# Get list of Table Metadata, i.e. id, name, rs ...
#
TABLE_LIST=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/table-metadata?ruleset_id=${RSID}&page_number=1"`
#echo "${TABLE_LIST}" | jq "."
#    {
#      "tableMetadataId": 105,
#      "tableName": "EMPLOYEES",
#      "rulesetId": 8
#    },

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

      #
      # Get tableMetadataId from previous rule set table list ...
      #
      TBL_META_ID=`echo "${TABLE_LIST}" | jq --raw-output ".responseList[] | select (.tableName==\"${TAB2}\") | .tableMetadataId"`
      #echo "Table Id: ${TBL_META_ID}"

      # 
      # Get Column MetaData iff new Table Name ...
      #
      if [[ "${TAB2_PREV}" != "${TAB2}" ]] 
      then
         META_STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/column-metadata?table_metadata_id=${TBL_META_ID}&page_number=1"`
         #echo "${META_STATUS}" | jq "."
      fi

      VAL2=`echo $line2 | awk -F"," '{ print $2 }'`
      VAL3=`echo $line2 | awk -F"," '{ print $3 }'`
      VAL4=`echo $line2 | awk -F"," '{ print $4 }'`
      VAL5=`echo $line2 | awk -F"," '{ print $5 }'`

      ## Get columnMetadataId ...
      COL_META_ID=`echo "${META_STATUS}" | jq --raw-output ".responseList[] | select (.columnName==\"${NAM2}\") | .columnMetadataId"`
      #echo "Column Meta Id: ${COL_META_ID}"

      # 
      # Have User Input and valid column meta data id ...
      #
      if [[ "${VAL2}" != "" ]] && [[ "${COL_META_ID}" != "" ]]
      then
         echo "Updating Domain and Algorithm for ${TAB2}.${NAM2} with columnMetadataId=${COL_META_ID} ..."
         JSON="{
   \"algorithmName\": \"${VAL3}\", 
   \"domainName\": \"${VAL2}\" 
"
         if [[ "${VAL2}" == "DOB" ]]
         then
            JSON="${JSON}, 
   \"dateFormat\": \"${VAL5}\"
"
         fi

         VTMP4="true"
         if [[ "${VAL4}" == "User" ]]
         then
            VTMP4="false"
         fi
         JSON="${JSON},
   \"isProfilerWritable\": ${VTMP4}
}"
         if [[ "${SHOW_JSON}" == "YES" ]]
         then
            echo $JSON
         fi
         #
         # Update (PUT) column-metadata, i.e. add domain and algorithm ...
         #
         RESULTS=`curl -s -X PUT --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "${JSON}" "${DMURL}/column-metadata/${COL_META_ID}"`
         if [[ "${SHOW_JSON}" == "YES" ]]
         then 
            echo "${RESULTS}"
         fi
         # {"errorMessage":"Missing required field 'dateFormat'"}
         ERR_CHK=`echo "${RESULTS}" | jq -r ".errorMessage | select (.!=null) "`
         if [[ "${ERR_CHK}" != "" ]] 
         then
            echo "ERROR: see above message, exiting ..."
            exit 1
         fi 
      fi 	# end if VAL2 != ""
   fi   	# end if comment line
   #
   # Reset/Set loop variables ...
   #
   FQN2=""
   NAM2=""
   TAB2_PREV="${TAB2}"
   TAB2=""
   VAL2=""
   VAL3=""
   VAL4=""
   VAL5=""
   k=$((k+1))

done < ${M_SOURCE}

########################################################
## Create Masking Job ...

echo "---------------------------------------------------"
echo "Creating Masking Job ${M_MASK_NAME} ..."
json="{ 
   \"jobName\": \"${M_MASK_NAME}\", 
   \"rulesetId\": ${RSID}, 
   \"jobDescription\": \"Created File MaskingJob from API\", 
   \"feedbackSize\": 10000, 
   \"minMemory\": 1024,
   \"maxMemory\": 1024,
   \"onTheFlyMasking\": false, 
   \"databaseMaskingOptions\": { 
     \"batchUpdate\": true, 
     \"commitSize\": 10000, 
     \"dropConstraints\": true 
   } 
}"

#     \"commitSize\": 10000,
#     \"prescript\": {
#       \"name\": \"my_prescript.sql\",
#       \"contents\": \"ALTER TABLE table_name DROP COLUMN column_name;\"
#     },
#     \"postscript\": {
#       \"name\": \"my_postscript.sql\",
#       \"contents\": \"ALTER TABLE table_name ADD column_name VARCHAR(255);\"
#     }

RESULTS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "${json}" "${DMURL}/masking-jobs"`

JOBID=`echo ${RESULTS} | jq --raw-output ".maskingJobId" `
echo "job_id: ${JOBID}"

if [[ "${M_RUN_JOB}" == "YES" ]]
then

   echo "=================================================================="

   #########################################################
   ## Execute Masking Job ...

   echo "Running Masking JobID ${JOBID} ..."
   STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"jobId\": ${JOBID} }" "${DMURL}/executions"`
   #echo ${STATUS} | jq "."
   EXID=`echo "${STATUS}" | jq --raw-output ".executionId"`
   echo "Execution Id: ${EXID}"

   #########################################################
   ## Monitor Job Status ...

   JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
   sleep 1
   while [[ "${JOBSTATUS}" == "RUNNING" ]]
   do
      STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/executions/${EXID}"`
      #echo ${STATUS} | jq "."
      JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
      #echo "${JOBSTATUS}" 
      printf "."
      sleep ${DELAYTIMESEC}   
   done
   printf "\n"

   if [[ "${JOBSTATUS}" != "SUCCEEDED" ]]
   then
      echo "Job Error: $JOBSTATUS ... $STATUS"
   else
      echo "Masking Job Completed: $JOBSTATUS"
      echo ${STATUS} | jq "."
   fi

   echo "Please Verify Masked Table Data: ${M_SOURCE}"

fi	# end if ${M_RUN_JOB}

#####################################################
## Data Post-Processing ...

############## E O F ####################################
echo "Done."
exit 

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
# Copyright (c) 2017 by Delphix. All rights reserved.
#
# Program Name : provision_oracle_jq.sh
# Description  : Provision an Oracle VDB Example 
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: ./provision_oracle_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for Database Link and Sync ...
#
SOURCE_SID="orcl"                 # dSource name used to get db container reference value

VDB_NAME="VBITT"                  # Delphix VDB Name
MOUNT_BASE="/mnt/provision"       # Delphix Engine Mount Path 
DELPHIX_GRP="Oracle Source"       # Delphix Engine Group Name

TARGET_ENV="Linux Source"         # Target Environment used to get repository reference value
TARGET_HOME="/u01/app/oracle/product/11.2.0.4/db_1"   # Target Instance within Environment

ARCHIVELOGMODE="false"            # true or false ONLY

#
# Optional: Oracle Init Parameters Template ...
#
# Delphix5120HWv8> database template list display=name,reference;
# 
# Uncomment template line if applicable ...
#
ORACLE_INIT_TPL=""
#ORACLE_INIT_TPL='"configTemplate": "DATABASE_TEMPLATE-1",'

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get Group Reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "group: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference for name ${DELPHIX_GRP} ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   echo "Error: No container found for ${SOURCE_SID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1;
fi


#########################################################
## Get Environment reference  

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "environment: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference for name of $TARGET_ENV ...
# 
ENV_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TARGET_ENV}"'") | .reference '`
echo "env reference: ${ENV_REFERENCE}"

#########################################################
## Get Repository reference  

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "repository: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference for name of $ENV_REFERENCE ...
# 
REP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .name=="'"${TARGET_HOME}"'") | .reference '`
echo "repository reference: ${REP_REFERENCE}"

#########################################################
## Get API Version Info ...

#echo "About API "
STATUS=`curl -s -X GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo ${STATUS} | jq "."

#
# Get Delphix Engine API Version ...
#
major=`echo ${STATUS} | jq --raw-output ".result.apiVersion.major"`
minor=`echo ${STATUS} | jq --raw-output ".result.apiVersion.minor"`
micro=`echo ${STATUS} | jq --raw-output ".result.apiVersion.micro"`

let apival=${major}${minor}${micro}
echo "Delphix Engine API Version: ${major}${minor}${micro}"

if [ "$apival" == "" ]
then
   echo "Error: Delphix Engine API Version Value Unknown $apival ..."
else
   echo "Delphix Engine API Version: ${major}${minor}${micro}"
fi


#########################################################
## Provision an Oracle Database ...

json="{
    \"type\": \"OracleProvisionParameters\",
    \"container\": {
        \"type\": \"OracleDatabaseContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\"
    },
    \"source\": {
        \"type\": \"OracleVirtualSource\","
#
# Version Specific JSON parameter requirement for Illium ...
#
if [ $apival -ge 180 ]
then
json="${json}
        \"allowAutoVDBRestartOnHostReboot\": false,"
fi
#
# Optional: Oracle Init Parameters Template ...
#
json="${json}
${ORACLE_INIT_TPL}"
#
# Continue Building JSON Data String ...
#
json="${json}
        \"archivelogMode\": ${ARCHIVELOGMODE},
        \"mountBase\": \"${MOUNT_BASE}\"
    },
    \"sourceConfig\": {
        \"type\": \"OracleSIConfig\",
        \"repository\": \"${REP_REFERENCE}\",
        \"databaseName\": \"${VDB_NAME}\",
        \"uniqueName\": \"${VDB_NAME}\",
        \"instance\": {
            \"type\": \"OracleInstance\",
            \"instanceName\": \"${VDB_NAME}\",
            \"instanceNumber\": 1
        }
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\"  
    }
}"

echo "Provisioning json=$json"

echo "Provisioning VDB from Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

#echo "Database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#########################################################
#
# Get Job Number ...
#
JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

#########################################################
#
# Job Information ...
#
JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${JOB_STATUS}" "status" )

#########################################################
#
# Get Job State from Results, loop until not RUNNING  ...
#
JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
while [ "${JOBSTATE}" == "RUNNING" ]
do
   echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
   sleep ${DELAYTIMESEC}
   JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
   PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
done

#########################################################
##  Producing final status

if [ "${JOBSTATE}" != "COMPLETED" ]
then
   echo "Error: Delphix Job Did not Complete, please check GUI ${JOB_STATUS}"
#   exit 1
else 
   echo "Job: ${JOB} ${JOBSTATE} ${PERCENTCOMPLETE}% Completed ..."
fi

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


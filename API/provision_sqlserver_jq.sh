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
# Program Name : provision_sqlserver_jq.sh
# Description  : Delphix API to provision a SQLServer VDB
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
# Usage: ./provision_sqlserver_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#
# Required for Povisioning Virtual Database ...
#
SOURCE_SID="delphixdb"           # dSource name used to get db container reference value

VDB_NAME="Vdelphixdb"            # Delphix VDB Name
DELPHIX_GRP="Windows_Target"     # Delphix Engine Group Name

TARGET_ENV="Windows Host"        # Target Environment used to get repository reference value 
TARGET_REP="MSSQLSERVER"         # Target Environment Repository / Instance name

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Session and Login ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get API Version Info ...

APIVAL=$( jqGet_APIVAL )
if [ "${APIVAL}" == "" ]
then
   echo "Error: Delphix Engine API Version Value Unknown ${APIVAL} ..."
else
   echo "Delphix Engine API Version: ${APIVAL}"
fi

#########################################################
## Get or Create Group 

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get Environment reference  

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference for name of $TARGET_ENV ...
# 
ENV_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TARGET_ENV}"'") | .reference '`
echo "env reference: ${ENV_REFERENCE}"

#########################################################
## Get Repository reference  

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Repository Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference for name of $ENV_REFERENCE ...
# 
#duplicate names produce more than one result#
#REP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.instanceName=="'"${TARGET_REP}"'") | .reference '`
#echo "repository reference: ${REP_REFERENCE}"

REP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .instanceName=="'"${TARGET_REP}"'") | .reference '`
echo "Source repository reference: ${REP_REFERENCE}"

#########################################################
## Provision a SQL Server Database ...

json="
{
    \"type\": \"MSSqlProvisionParameters\",
    \"container\": {
        \"type\": \"MSSqlDatabaseContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\",
        \"sourcingPolicy\": {
            \"type\": \"SourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": false
        },
        \"validatedSyncMode\": \"TRANSACTION_LOG\"
    },
    \"source\": {
        \"type\": \"MSSqlVirtualSource\","

#
# Version Specific JSON parameter requirement for Illium ...
#
if [ $APIVAL -ge 180 ]
then
json="${json}
        \"allowAutoVDBRestartOnHostReboot\": false,"
fi

json="${json}
        \"operations\": {
            \"type\": \"VirtualSourceOperations\",
            \"configureClone\": [],
            \"postRefresh\": [],
            \"postRollback\": [],
            \"postSnapshot\": [],
            \"preRefresh\": [],
            \"preSnapshot\": []
        }
    },
    \"sourceConfig\": {
        \"type\": \"MSSqlSIConfig\",
        \"linkingEnabled\": false,
        \"repository\": \"${REP_REFERENCE}\",
        \"databaseName\": \"${VDB_NAME}\",
        \"recoveryModel\": \"SIMPLE\",
        \"instance\": {
            \"type\": \"MSSqlInstanceConfig\",
            \"host\": \"${ENV_REFERENCE}\"
        }
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\",
        \"location\": \"LATEST_SNAPSHOT\"
    }
}
"

echo "JSON: ${json}" 

echo "Provisioning VDB from Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`


echo "Database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#########################################################
#
# Get Job Number ...
#
JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

jqJobStatus "${JOB}"            # Job Status Function ...

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


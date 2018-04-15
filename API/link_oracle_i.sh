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
# Program Name : link_oracle_i.sh
# Description  : Delphix API to link/ingest a dSource
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
# Usage: ./link_oracle_i.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for Database Link and Sync ...
#
DELPHIX_NAME="orcl"               # Delphix dSource Name
DELPHIX_GRP="Oracle_Source"       # Delphix Group Name

SOURCE_ENV="Linux Host"           # Source Enviroment Name
SOURCE_SID="orcl"                 # Source Environment Database SID
DB_USER="delphixdb"               # Source Database SID user account
DB_PASS="delphixdb"               # Source Database SID user password

#
# Optional: Source Policy ...
#
# Delphix5150HWv8 database link linkData sourcingPolicy *> set logsyncMode= [ ARCHIVE_ONLY_MODE  ARCHIVE_REDO_MODE  UNDEFINED ]
#
SOURCE_POLICY="        ,\"sourcingPolicy\": {
            \"type\": \"OracleSourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": true,
            \"logsyncInterval\": 5,
            \"logsyncMode\": \"ARCHIVE_REDO_MODE\"
        }
"
# or don't set it by uncommenting the next line ...
# SOURCE_POLICY=""

#
# Optional: Add if default SnapSync Policy is None ...
#
#LINK_NOW="       , \"linkNow\": true"
LINK_NOW=""

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
## Get Group Reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference for name ${DELPHIX_GRP} ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get sourceconfig reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out sourceconfig reference for name of $SOURCE_SID ...
#
SOURCE_CFG=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Get Environment primaryUser  

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out primaryUser for name of $SOURCE_ENV ...
# 
PRIMARYUSER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_ENV}"'") | .primaryUser '`
echo "primaryUser reference: ${PRIMARYUSER}"

#########################################################
## Link Source Database ...

echo "Linking Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/link -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LinkParameters",
    "group": "${GROUP_REFERENCE}",
    "linkData": {
        "type": "OracleLinkData",
        "config": "${SOURCE_CFG}",
        "dbCredentials": {
            "type": "PasswordCredential",
            "password": "${DB_PASS}"
        },
        "dbUser": "${DB_USER}",
        "environmentUser": "${PRIMARYUSER}"
${SOURCE_POLICY}
${LINK_NOW}
    },
    "name": "${DELPHIX_NAME}"
}
EOF
`

#echo "Database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Fast Job, allow to finish before while ...
#
sleep 2

#
# Get Database Container Value ...
#
CONTAINER=$( jqParse "${STATUS}" "result" )
echo "Container: ${CONTAINER}"

#########################################################
#
# Get Job Number ...
#
JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

jqJobStatus "${JOB}"            # Job Status Function ...

#########################################################
#
# sync snapshot ...
#
echo "Running SnapSync ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/${CONTAINER}/sync -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "OracleSyncParameters"
}
EOF
`

#echo ${STATUS}
# {"type":"OKResult","status":"OK","result":"","job":"JOB-49","action":"ACTION-232"}
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


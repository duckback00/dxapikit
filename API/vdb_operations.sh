#!/bin/sh
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
# Program Name : vdb_operations.sh
# Description  : API calls to perform basic operations on a VDB
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.2
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#
# Interactive Usage: ./vdb_operations.sh
# 
# Non-Interactive Usage: ./vdb_operations [sync | refresh | rollback] [VDB_Name]
#
# Delphix Docs Reference:
#   https://docs.delphix.com/docs/reference/web-service-api-guide
#
#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
## Authentication ...

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
#
# Command Line Arguments ...
#
ACTION=$1
if [[ "${ACTION}" == "" ]] 
then
   echo "Usage: ./vdb_operations [sync | refresh | rollback] [VDB_Name]"
   echo "---------------------------------"
   echo "sync refresh rollback"
   echo "Please Enter Operation: "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
fi;
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

SOURCE_SID="$2"
if [[ "${SOURCE_SID}" == "" ]]
then

   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
   echo "---------------------------------"
   echo "VDB Names: [copy-n-paste]"
   echo "${VDB_NAMES}"
   echo " "

   echo "Please Enter dSource or VDB Name (case sensitive): "
   read SOURCE_SID
   if [ "${SOURCE_SID}" == "" ]
   then
      echo "No dSource or VDB Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export SOURCE_SID

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "database container reference: ${CONTAINER_REFERENCE}"
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   echo "Error: No container found for ${SOURCE_SID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1;
fi

#
# Parse out container type ...
#
CONTAINER_TYPE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .type '`
echo "database container type: ${CONTAINER_TYPE}"

#########################################################
## Get provision source database container

STATUS=`curl -s -X GET -k ${BaseURL}/database/${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#echo "${STATUS}"
PARENT_SOURCE=`echo ${STATUS} | jq --raw-output '.result | select(.reference=="'"${CONTAINER_REFERENCE}"'") | .provisionContainer '`
echo "provision source container: ${PARENT_SOURCE}"

#########################################################
## type values ...

#sync *> set type=
#ASELatestBackupSyncParameters
#ASENewBackupSyncParameters
#ASESpecificBackupSyncParameters
#AppDataSyncParameters
#MSSqlExistingMostRecentBackupSyncParameters
#MSSqlExistingSpecificBackupSyncParameters
#MSSqlNewCopyOnlyFullBackupSyncParameters
#MySQLExistingMySQLDumpSyncParameters
#MySQLNewMySQLDumpSyncParameters
#MySQLXtraBackupSyncParameters
#OracleSyncParameters
#PgSQLSyncParameters
#SyncParameters

#
# Defaults for non-coded container types ...
#
SYNC_TYPE="SyncParameters"
REFRESH_TYPE="RefreshParameters"
ROLLBACK_TYPE="RollbackParameters"

if [[ "${CONTAINER_TYPE}" == "OracleDatabaseContainer" ]]
then
   SYNC_TYPE="OracleSyncParameters"
   REFRESH_TYPE="OracleRefreshParameters"
   ROLLBACK_TYPE="OracleRollbackParameters"
fi
if [[ "${CONTAINER_TYPE}" == "MSSqlDatabaseContainer" ]]
then
   # MSSqlExistingMostRecentBackupSyncParameters
   # MSSqlExistingSpecificBackupSyncParameters
   # MSSqlNewCopyOnlyFullBackupSyncParameters
   SYNC_TYPE="MSSqlExistingMostRecentBackupSyncParameters"
   REFRESH_TYPE="RefreshParameters"
   ROLLBACK_TYPE="RollbackParameters"
fi
if [[ "${CONTAINER_TYPE}" == "AppDataContainer" ]]
then
   SYNC_TYPE="AppDataSyncParameters"
   REFRESH_TYPE="RefreshParameters"
   ROLLBACK_TYPE="RollbackParameters"
fi

#########################################################
## Perform Action ... 

case ${ACTION} in
sync)

   json="{
   \"type\": \"${SYNC_TYPE}\"
}"

;;
refresh)

   json="{
    \"type\": \"${REFRESH_TYPE}\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${PARENT_SOURCE}\"
    }
}"

;;
rollback)

   json="{
    \"type\": \"${ROLLBACK_TYPE}\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\"
    }
}"

;;
*)

  echo "Unknown option (sync | refresh | rollback): ${ACTION}"
  echo "Exiting ..."
  exit 1;

;;
esac

echo "json> ${json}"

#
# Submit VDB operations request ...
#
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/${CONTAINER_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

#########################################################
#
# Get Job Number ...
#
JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

jqJobStatus "${JOB}"            # Job Status Function ...

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


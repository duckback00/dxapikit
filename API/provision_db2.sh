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
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Program Name : provision_db2.sh
# Description  : Provision an DB2 VDB Non-HDR Example
# Author       : Alan Bitterman
# Created      : 2018-06-14
# Version      : v1.0
# Platforms    : ONLY works with Delphix Version 5.2.x or later
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage: 
# ./provision_db2.sh
#
# Non-interactive Usage:
#                    dSource  VDB     Group     Host         Instance             User
# ./provision_db2.sh "HRDB" "VHRDB" "Targets" "Target" "db2inst1 - 10.5.0.1 - " "db2inst1"
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

DEF_SOURCE_SID="HRDB"                       # dSource name used to get db container reference value
#DEV_VDB_NAME="VHRDB"                       # Delphix VDB Name
#DEF_DELPHIX_GRP="Targets"                  # Delphix Engine Group Name
#DEF_TARGET_ENV="Target"                    # Target Environment used to get repository reference value 
#DEF_TARGET_HOME="db2inst1 - 10.5.0.1 - "   # Target Instance within Environment 
#DEF_TARGET_USER="db2inst1"

DEF_SOURCE_SID=""
DEF_VDB_NAME=""
DEF_DELPHIX_GRP=""
DEF_TARGET_ENV=""
DEF_TARGET_HOME=""
DEF_TARGET_USER=""

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

. ./jqJSON_subroutines.sh

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
## Get API Version Info ...

APIVAL=$( jqGet_APIVAL )
if [ "${APIVAL}" == "" ]
then
   echo "Error: Delphix Engine API Version Value Unknown ${APIVAL} ..."
else
   echo "Delphix Engine API Version: ${APIVAL}"
fi

#########################################################
## Get database container ...

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "database: ${STATUS}"
#echo "${STATUS}" | jq "."
RESULTS=$( jqParse "${STATUS}" "status" )

SOURCE_SID="${1}"
if [[ "${SOURCE_SID}" == "" ]]
then
   ZTMP="Enter dSource or VDB Name to Provision"
   if [[ "${DEF_SOURCE_SID}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read SOURCE_SID
      if [[ "${SOURCE_SID}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      SOURCE_SID=${DEF_SOURCE_SID}
   fi
fi

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
## VDB Name from Command Line Parameters ...

VDB_NAME="${2}"
ZTMP="New VDB Name"
if [[ "${VDB_NAME}" == "" ]]
then
   if [[ "${DEF_VDB_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter ${ZTMP} (case-sensitive): "
      read VDB_NAME
      if [[ "${VDB_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_NAME=${DEF_VDB_NAME}
   fi
fi
echo "${ZTMP}: ${VDB_NAME}"

#########################################################
## Get Group Reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "group: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

DELPHIX_GRP="${3}"
if [[ "${DELPHIX_GRP}" == "" ]]
then
   ZTMP="Delphix Target Group/Folder"
   if [[ "${DEF_DELPHIX_GRP}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read DELPHIX_GRP
      if [[ "${DELPHIX_GRP}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      DELPHIX_GRP=${DEF_DELPHIX_GRP}
   fi
fi

#
# Parse out group reference for name ${DELPHIX_GRP} ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get Environment reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."
#echo "environment: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

TARGET_ENV="${4}"
if [[ "${TARGET_ENV}" == "" ]]
then
   ZTMP="Target Environment"
   if [[ "${DEF_TARGET_ENV}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.type=="UnixHostEnvironment") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read TARGET_ENV
      if [[ "${TARGET_ENV}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      TARGET_ENV=${DEF_TARGET_ENV}
   fi
fi

# 
# Parse out reference for name of $TARGET_ENV ...
# 
ENV_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TARGET_ENV}"'") | .reference '`
echo "env reference: ${ENV_REFERENCE}"

#########################################################
## Get Repository reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "repository: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

TARGET_HOME="${5}"
if [[ "${TARGET_HOME}" == "" ]]
then
   ZTMP="Target Home Repository"
   if [[ "${DEF_TARGET_HOME}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select(.type=="AppDataRepository" and .environment=="'"${ENV_REFERENCE}"'") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read TARGET_HOME
      if [[ "${TARGET_HOME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      TARGET_HOME=${DEF_TARGET_HOME}
   fi
fi

# 
# Parse out reference for name of $ENV_REFERENCE ...
# 
if [[ "${TARGET_HOME}" = *"\""* ]]
then
   REP_REFERENCE=`echo "${STATUS}" | jq --raw-output ".result[] | select(.environment==\"${ENV_REFERENCE}\" and .name==${TARGET_HOME}) | .reference "`
else
   REP_REFERENCE=`echo "${STATUS}" | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .name=="'"${TARGET_HOME}"'") | .reference '`
fi
echo "repository reference: ${REP_REFERENCE}"
if [[ "${REP_REFERENCE}" == "" ]]
then
   echo "Error: No repository reference found for ${TARGET_ENV} and ${TARGET_HOME}, please verify values. Exiting ..."
   exit 1;
fi

#########################################################
## Get User reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/environment/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "env users: ${STATUS}"

TARGET_USER="${6}"
if [[ "${TARGET_USER}" == "" ]]
then
   ZTMP="Target User"
   if [[ "${DEF_TARGET_USER}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read TARGET_USER
      if [[ "${TARGET_USER}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      TARGET_USER=${DEF_TARGET_USER}
   fi
fi

USER_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .name=="'"${TARGET_USER}"'") | .reference '`
echo "user reference: ${USER_REF}"

#########################################################
## Provision a DB2 Database ...

json="{
    \"type\": \"AppDataProvisionParameters\",
    \"container\": {
        \"type\": \"AppDataContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\"
    },
    \"source\": {
        \"type\": \"AppDataVirtualSource\",
        \"parameters\": {
            \"databaseAliasName\": \"${VDB_NAME}\"
        },
        \"allowAutoVDBRestartOnHostReboot\": false
    },
    \"sourceConfig\": {
        \"type\": \"AppDataDirectSourceConfig\",
        \"name\": \"\",
        \"environmentUser\": \"${USER_REF}\",
        \"repository\": \"${REP_REFERENCE}\",
        \"path\": \"\"
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

jqJobStatus "${JOB}"            # Job Status Function ...

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


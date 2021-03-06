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
# Program Name : jetstream_container_restore_to_timestamp_jq.sh 
# Description  : Delphix API to restore a JetStream Containers Active Branch to a TimeStamp
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.0
# Valid Since  : Session Version 1.9.0 - Delphix Engine Version 5.2
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage:
# ./jetstream_container_restore_to_timestamp_jq.sh
#
# Non-interactive Usage: 
# ./jetstream_container_restore_to_timestamp_jq.sh [template_name] [container_name] [timestamp]
#
# [timestamp] Format: YYYY-MM-DDTHH:MI:SS.FFFZ   
#  Example Timestamp: 2017-11-18T18:25:21.304Z
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
#
#DEF_JS_TEMPLATE="tpl"           # Jetstream Template Name
#DEF_JS_CONTAINER_NAME="dc"      # Jetstream Container Name
#DEF_TS="2017-11-18T18:39:26.722Z"	# Timestamp
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_CONTAINER_NAME=""
DEF_TS=""

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

#########################################################
## Get API Version Info ...

APIVAL=$( jqGet_APIVAL )
if [[ "${APIVAL}" == "" ]]
then
   echo "Error: Delphix Engine API Version Value Unknown ${APIVAL} ..."
else
   echo "Delphix Engine API Version: ${APIVAL}"
fi

#########################################################
## Get Template Reference ...

#echo "Getting Jetstream Template Reference ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

JS_TEMPLATE="${1}"
if [[ "${JS_TEMPLATE}" == "" ]]
then
   ZTMP="Template Name"
   if [[ "${DEF_JS_TEMPLATE}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read JS_TEMPLATE
      if [[ "${JS_TEMPLATE}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_TEMPLATE="${DEF_JS_TEMPLATE}"
   fi
fi
echo "template name: ${JS_TEMPLATE}"

#
# Parse ...
#
JS_TPL_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${JS_TEMPLATE}"'") | .reference '`
echo "template reference: ${JS_TPL_REF}"

if [[ "${JS_TPL_REF}" == "" ]]
then
   echo "${ZTMP} Reference ${JS_TPL_REF} for ${JS_TEMPLATE} not found, Exiting ..."
   exit 1
fi

#JS_ACTIVE_BRANCH_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${JS_TEMPLATE}"'") | .activeBranch '`
#echo "active template branch reference: ${JS_ACTIVE_BRANCH_REF}"

#########################################################
## Get container reference...

#echo "Getting Jetstream Template Container Reference ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

JS_CONTAINER_NAME="${2}"
if [[ "${JS_CONTAINER_NAME}" == "" ]]
then
   ZTMP="Container Name"
   if [[ "${DEF_JS_CONTAINER_NAME}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.template=="'"${JS_TPL_REF}"'") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read JS_CONTAINER_NAME
      if [[ "${JS_CONTAINER_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_CONTAINER_NAME="${DEF_JS_CONTAINER_NAME}"
   fi
fi
echo "template container name: ${JS_CONTAINER_NAME}"

JS_CONTAINER_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .reference '`
echo "template container reference: ${JS_CONTAINER_REF}"

if [[ "${JS_CONTAINER_REF}" == "" ]]
then
   echo "${ZTMP} Reference ${JS_CONTAINER_REF} for ${JS_CONTAINER_NAME} not found, Exiting ..."
   exit 1
fi

JS_DC_ACTIVE_BRANCH=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .activeBranch '`
echo "Container Active Branch Reference: ${JS_DC_ACTIVE_BRANCH}"

JS_DC_LAST_UPDATED=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .lastUpdated '`

#########################################################
## Get Active Branch Reference ...

#echo "Getting Jetstream Branch Reference Value ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch/${JS_DC_ACTIVE_BRANCH} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

ACTIVE_BRANCH_NAME=`echo "${STATUS}" | jq --raw-output '.result.name'`
echo "Active Branch Name: ${ACTIVE_BRANCH_NAME}"

#
# Muse use Active Branch ...
#
JS_BRANCH_REF="${JS_DC_ACTIVE_BRANCH}"

if [[ "${JS_BRANCH_REF}" == "" ]]
then
   echo "Branch Reference ${JS_BRANCH_REF} for Active Branch not found, Exiting ..."
   exit 1
fi

#########################################################
## Get Remaining Command Line Parameters ...

TS="${3}"
if [[ "${TS}" == "" ]]
then
   if [[ "${DEF_TS}" == "" ]]
   then
      echo "---------------------------------"
      echo "Timestamp Format: YYYY-MM-DDTHH:MI:SS.FFFZ"
      echo "Container Last Updated: ${JS_DC_LAST_UPDATED}"
      echo "Please Enter Timestamp: "
      read TS
      if [[ "${TS}" == "" ]]
      then
         echo "No Timestamp Name Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No Timestamp Provided, using Default ..."
      TS=${DEF_TS}
   fi
fi

#########################################################
## Container Restore using Timestamp ...

if [[ $APIVAL -lt 190 ]]
then

   json="
{
       \"type\": \"JSTimelinePointTimeInput\"
      ,\"time\": \"${TS}\"
      ,\"branch\": \"${JS_BRANCH_REF}\"
    }
}"

else

   # J 190 ...
   json="
{
    \"timelinePointParameters\": {
       \"type\": \"JSTimelinePointTimeInput\"
      ,\"time\": \"${TS}\"
      ,\"branch\": \"${JS_BRANCH_REF}\"
    }
    ,\"type\": \"JSDataContainerRestoreParameters\"
    ,\"forceOption\": false
}"

fi

echo "JSON: ${json}"

STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/container/${JS_CONTAINER_REF}/restore -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "JetStream Container Restore to Timestamp Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

sleep 2

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


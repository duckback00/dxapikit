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
# Program Name : jetstream_create_branch_from_timestamp_jq.sh
# Description  : Delphix API to create Container Branch from Timestamp
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.2
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage:
# ./jetstream_create_branch_from_timestamp_jq.sh
#
# ... or ...
#
# Non-Interactive Usage:
# ./jetstream_create_branch_from_timestamp_jq.sh [template_name] [container_name] [branch_name]
#
# ./jetstream_create_branch_from_timestamp_jq.sh tpl cdc default
# ./jetstream_create_branch_from_timestamp_jq.sh tpl cdc 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
#
#DEF_JS_TEMPLATE="tpl"              # Jetstream Template Name
#DEF_JS_CONTAINER_NAME="dc"         # Jetstream Container Name
#DEF_JS_BRANCH_NAME="default"       # Jetstream Branch Name
#DEF_BRANCH_NAME="Branch_${DT}"     # New Branch Name ...
#DEF_TS="2017-11-18T18:39:26.722Z"  # Timestamp

#
# For full interactive options ...
#
DEF_JS_TEMPLATE=""
DEF_JS_CONTAINER_NAME=""
DEF_JS_BRANCH_NAME=""
DEF_BRANCH_NAME=""  
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

echo "Session and Login Successful ..."

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

#JS_DC_ACTIVE_BRANCH=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .activeBranch '`
#echo "Container Active Branch Reference: ${JS_DC_ACTIVE_BRANCH}"

JS_DC_LAST_UPDATED=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .lastUpdated '`

#########################################################
## Get Branch Reference ...

#echo "Getting Jetstream Branch Reference Value ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

#JS_DAB_NAME=`echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_DC_ACTIVE_BRANCH}"'") | .name '`
#echo "Active Branch Name: ${JS_DAB_NAME}"

JS_BRANCH_NAME="${3}"
if [[ "${JS_BRANCH_NAME}" == "" ]]
then
   ZTMP="Branch Name"
   if [[ "${DEF_JS_BRANCH_NAME}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.dataLayout=="'"${JS_CONTAINER_REF}"'") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read JS_BRANCH_NAME
      if [[ "${JS_BRANCH_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_BRANCH_NAME="${DEF_JS_BRANCH_NAME}"
   fi
fi
echo "branch name: ${JS_BRANCH_NAME}"

#
# Parse ...
#
JS_BRANCH_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${JS_BRANCH_NAME}"'" and .dataLayout=="'"${JS_CONTAINER_REF}"'") | .reference '`
echo "branch reference: ${JS_BRANCH_REF}"

if [[ "${JS_BRANCH_REF}" == "" ]]
then
   echo "${ZTMP} Reference ${JS_BRANCH_REF} for ${JS_BRANCH_NAME} not found, Exiting ..."
   exit 1
fi

#echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_BRANCH_REF}"'")'

# 
# TODO: Show start and latest timeflow timestamps for branch ...
# 

#########################################################
## Get Remaining Command Line Parameters ...


BRANCH_NAME="${4}"
if [[ "${BRANCH_NAME}" == "" ]]
then
   if [[ "${DEF_BRANCH_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter New Branch Name: "
      read BRANCH_NAME
      if [[ "${BRANCH_NAME}" == "" ]]
      then
         echo "No New Branch Name Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No New Branch Name Provided, using Default ${DEF_BRANCH_NAME} ..."
      BRANCH_NAME=${DEF_BRANCH_NAME}
   fi
fi

TS="${5}"
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
      echo "No Timestamp Provided, using Default ${DEF_TS} ..."
      TS=${DEF_TS}
   fi
fi

#########################################################
## Create Branch Options ...

#
# Create Branch using specified Timestamp ...
#
json="
{
    \"type\": \"JSBranchCreateParameters\",
    \"dataContainer\": \"${JS_CONTAINER_REF}\",
    \"name\": \"${BRANCH_NAME}\",
    \"timelinePointParameters\": {
        \"type\": \"JSTimelinePointTimeInput\",
        \"branch\": \"${JS_BRANCH_REF}\",
        \"time\": \"${TS}\"
    }
}
"

# Create Branch using Latest Timestamp ...
# Create Branch using Bookmark ...

echo "$json"

#########################################################
## Creating Branch ...

echo "Creating Branch ${BRANCH_NAME} ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "Create Branch Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

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


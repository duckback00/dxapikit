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
# Program Name : jetstream_container_delete_jq.sh 
# Description  : Delphix API to delete a JetStream Container
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage: 
# ./jetstream_container_delete_jq.sh
#
# Non-interactive Usage:
# ./jetstream_container_delete_jq.sh [template_name] [container_name]  Action   Delete_DataSource
# ./jetstream_container_delete_jq.sh [template_name] [container_name] [delete]   [true|false]
#
# ./jetstream_container_delete_jq.sh tpl cdc delete false
# ./jetstream_container_delete_jq.sh tpl cdc
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
#DEF_ACTION="delete"
#DEF_DEL_DS="false"
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_CONTAINER_NAME=""
DEF_ACTION=""
DEF_DEL_DS=""

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

#########################################################
#
# Get Remaining Command Line Parameters ...
#

#
# Delete Container ...
#
ACTION="${3}"
if [[ "${ACTION}" == "" ]]
then
   if [[ "${DEF_ACTION}" == "" ]]
   then
      echo "---------------------------------"
      echo "Action Option Selections: delete"
      echo "Please Enter Action Option: "
      read ACTION
      if [[ "${ACTION}" == "" ]]
      then
         echo "No Action Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No Action Provided, using Default ..."
      ACTION=${DEF_ACTION}
   fi
fi

if [[ "${ACTION}" != "delete" ]]
then
   echo "No Action Provided, Exiting ..."
   exit 0
fi

# 
# Delete Data Source ...
#
DEL_DS="${4}"
if [[ "${DEL_DS}" == "" ]]
then
   if [[ "${DEF_DEL_DS}" == "" ]]
   then
      echo "---------------------------------"
      echo "Delete Data Source Options: true | false"
      echo "Please Enter Delete Data Source Option: "
      read DEL_DS
      if [[ "${DEL_DS}" == "" ]]
      then
         echo "No Option Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No Option Provided, using Default ..."
      DEL_DS=${DEF_DEL_DS}
   fi
fi

#########################################################
## Delete Container ...
 
json="
{
    \"type\": \"JSDataContainerDeleteParameters\",
    \"deleteDataSources\": ${DEL_DS}
}"

echo "JSON: ${json}"

STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/container/${JS_CONTAINER_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "JetStream Delete Container Results: ${STATUS}"
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


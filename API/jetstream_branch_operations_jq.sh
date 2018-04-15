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
# Program Name : jetstream_branch_operations_jq.sh 
# Description  : Delphix API to list, activate or delete Container Branches
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.2
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Run interactive or non-interactive 
#
# Interactive Usage: 
# ./jetstream_branch_operations_jq.sh
#
# ... or ...
#
# Non-Interactive Usage:
# ./jetstream_branch_operations_jq.sh [template_name] [container_name] [branch_name] [list|activate|delete]
#
# ./jetstream_branch_operations_jq.sh tpl cdc default list
# ./jetstream_branch_operations_jq.sh tpl cdc default activate
# ./jetstream_branch_operations_jq.sh tpl cdc branch_break_fix delete
# 
# ./jetstream_branch_operations_jq.sh tpl cdc
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
#DEF_JS_BRANCH_NAME="default"    # Jetstream Branch Name
#DEF_ACTION="list"		 # Action [list|activate|delete]
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_CONTAINER_NAME=""
DEF_JS_BRANCH_NAME=""
DEF_ACTION=""

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
      JS_TEMPLATE=${DEF_JS_TEMPLATE}
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
      JS_CONTAINER_NAME=${DEF_JS_CONTAINER_NAME}
   fi
fi
echo "template container name: ${JS_CONTAINER_NAME}"

JS_CONTAINER_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .reference '`
echo "template datasource container reference: ${JS_CONTAINER_REF}"

if [[ "${JS_CONTAINER_REF}" == "" ]]
then
   echo "${ZTMP} Reference ${JS_CONTAINER_REF} for ${JS_CONTAINER_NAME} not found, Exiting ..."
   exit 1
fi

JS_DC_ACTIVE_BRANCH=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .activeBranch '`
echo "Container Active Branch Reference: ${JS_DC_ACTIVE_BRANCH}"

#########################################################
## Get Branch Reference ...

#echo "Getting Jetstream Branch Reference Value ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

JS_DAB_NAME=`echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_DC_ACTIVE_BRANCH}"'") | .name '`
echo "Active Branch Name: ${JS_DAB_NAME}"

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

#########################################################
#
# Command Line Arguments ...
#
# $4 = activate | delete

ACTION="${4}"
if [[ "${ACTION}" == "" ]]
then
   if [[ "${DEF_ACTION}" == "" ]]
   then
      echo "activate | delete | list"
      echo "Please Enter Branch Option: "
      read ACTION
      if [[ "${ACTION}" == "" ]]
      then
         echo "No Operation Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No Action Provided, using Default ..."
      ACTION=${DEF_ACTION}
   fi 
fi
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')

if [[ "${ACTION}" != "activate" ]] && [[ "${ACTION}" != "delete" ]] && [[ "${ACTION}" != "list" ]] 
then
   echo "Unknown Action ${ACTION}, please enter activate or delete, exiting ..."
   exit 1;
fi

#########################################################
## List Branch ...

if [[ "${ACTION}" == "list" ]]
then
   echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_BRANCH_REF}"'")'
   echo " "
   echo "# TODO: Fetch some meta data about the branch; such as valid timestamps, bookmarks, etc" 
   echo " "
   echo "Done ..."
   exit 0
fi

#########################################################
## Check / Validate BRANCH Reference ...

if [[ "${JS_BRANCH_REF}" == "" ]]
then
   echo "No Branch Name/Reference ${JS_BRANCH_NAME}/${JS_BRANCH_REF} found to ${ACTION}, Exiting ..."
   exit 1;
elif [[ "${JS_BRANCH_REF}" == "${JS_DC_ACTIVE_BRANCH}" ]]
then
   echo "${JS_BRANCH_NAME} Branch is already Active, unable to ${ACTION}, Exiting ..." 
   exit 1; 
fi

#########################################################
## Perform Action on Branch ...

echo "${ACTION} ${JS_BRANCH_NAME} Branch Reference ${JS_BRANCH_REF} ..."

if [[ "${ACTION}" == "activate" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch/${JS_BRANCH_REF}/activate -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

elif [[ "${ACTION}" == "delete" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch/${JS_BRANCH_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

else
   echo "Unknown Action: ${ACTION}, nothing executed ..."
   exit 0;
fi


echo "${ACTION} Branch Results: ${STATUS}"
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
exit 0


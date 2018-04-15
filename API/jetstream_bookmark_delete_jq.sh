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
# Program Name : jetstream_bookmark_delete_jq.sh 
# Description  : Delphix API to delete Self-Service Container Bookmarks
# Author       : Alan Bitterman
# Created      : 2017-09-25
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage: 
# ./jetstream_bookmark_delete_jq.sh
#
# Non-Interactive Usage:
# ./jetstream_bookmark_delete_jq.sh [template_name] [container_name] [branch_name] [bookmark_name] [delete] 
# ./jetstream_bookmark_delete_jq.sh tpl cdc default Wally delete
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
#DEF_JS_TEMPLATE="tpl"
#DEF_JS_CONTAINER_NAME="dc"
#DEF_JS_BRANCH_NAME="default"
#DEF_JS_BOOK_NAME="BM3"   # JetStream Bookmark Name_append timestamp
#DEF_ANS="delete"
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_CONTAINER_NAME=""
DEF_JS_BRANCH_NAME=""
DEF_JS_BOOK_NAME=""
DEF_ANS=""

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
      JS_TEMPLATE=${DEF_JS_TEMPLATE}
   fi
fi

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

JS_CONTAINER_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .reference '`
echo "template container reference: ${JS_CONTAINER_REF}"

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
      JS_BRANCH_NAME=${DEF_JS_BRANCH_NAME}
   fi
fi

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
## Get BookMarks per Branch Option ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

JS_BOOK_NAME="${4}"
if [[ "${JS_BOOK_NAME}" == "" ]]
then
   ZTMP="Bookmark Name"
   if [[ "${DEF_JS_BOOK_NAME}" == "" ]]
   then
      TMP=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${JS_CONTAINER_REF}"'" and .branch=="'"${JS_BRANCH_REF}"'") | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read JS_BOOK_NAME
      if [[ "${JS_BOOK_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_BOOK_NAME=${DEF_JS_BOOK_NAME}
   fi
fi

#
# Parse ...
#
JS_BOOK_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${JS_CONTAINER_REF}"'" and .branch=="'"${JS_BRANCH_REF}"'" and .name=="'"${JS_BOOK_NAME}"'") | .reference '`

#
# Validate ...
#
if [[ "${JS_BOOK_REF}" == "" ]]
then
   echo "No Bookmark Name/Reference ${JS_BOOK_NAME}/${JS_BOOK_REF} found, Exiting ..."
   exit 1;
fi

echo "Bookmark Reference: ${JS_BOOK_REF}"

#########################################################
## List Bookmark ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/bookmark/${JS_BOOK_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
echo "${STATUS}" | jq "."

#########################################################
## Prompt to Delete Bookmark ...

ANS="${5}"
if [[ "${ANS}" == "" ]]
then
   if [[ "${DEF_ANS}" == "" ]]
   then
      echo "---------------------------------"
      echo "Options: delete"
      echo "Please Enter Option : "
      read ANS
      if [[ "${ANS}" == "" ]]
      then
         echo "No Answer Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No Answer Provided, using Default ..."
      ANS=${DEF_ANS}
   fi
fi
ANS=$(echo "${ANS}" | tr '[:upper:]' '[:lower:]')

#
# Check Answer ... 
#
if [[ "${ANS}" != "delete" ]]
then
   echo " "
   echo "Done ..."
   echo " "
   exit 0
fi 

#########################################################
## Delete Bookmark ...

json="" 

echo "Delete Bookmark ${JS_BOOK_REF} ..."

STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/bookmark/${JS_BOOK_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "Delete Bookmark Results: ${STATUS}"
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
echo "Done ..."
echo " "
exit 0


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
# Program Name : jetstream_template_delete_jq.sh 
# Description  : Delphix API to delete a JetStream Template
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
# ./jetstream_template_delete_jq.sh
#
# Non-interactive Usage:
# ./jetstream_template_delete_jq.sh [template_name]  Action 
# ./jetstream_template_delete_jq.sh [template_name] [delete]
#
# ./jetstream_template_delete_jq.sh tpl delete 
# ./jetstream_template_delete_jq.sh tpl 
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
#DEF_JS_TEMPLATE="tpl"
#DEF_ACTION="delete"
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
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
      if [ "${JS_TEMPLATE}" == "" ]
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
#
# Get Remaining Command Line Parameters ...
#

#
# Delete Container ...
#
ACTION="${2}"
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

#########################################################
## Delete Template ...
 
STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/template/${JS_TPL_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

echo "JetStream Delete Template Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# exit gracefully since this API doesn't submit a job ...
#
echo " " 
echo "Done ... (no job required for this action)"
echo " "
exit 0


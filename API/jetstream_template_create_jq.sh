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
# Program Name : jetstream_template_create_jq.sh 
# Description  : Delphix API to create a JetStream Template
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: 
# ./jetstream_template_create_jq.sh
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
#DEF_JS_TEMPLATE="tpl_${DT}" 	# Jetstream Template Name  
#DEF_JS_DS_NAME="ds_${DT}"   	# JetStream Data Source Name
#DEF_DS_NAME="VBITT"		# Delphix dSource of VDB Name 
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_DS_NAME=""
DEF_DS_NAME=""

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
JS_TPL_CHK=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${JS_TEMPLATE}"'") | .name '`
if [[ "${JS_TPL_CHK}" != "" ]] || [[ "${JS_TEMPLATE}" == "" ]]
then    
   if [[ "${JS_TPL_CHK}" != "" ]] 
   then
      echo "Template Name ${JS_TEMPLATE} Already Exists, Please try again ..."
   fi
   ZTMP="New Template Name"
   if [[ "${DEF_JS_TEMPLATE}" == "" ]]
   then
      echo "Existing Template Names: "
      echo "${STATUS}" | jq --raw-output '.result[] | .name '
      echo "---------------------------------"
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

JS_TPL_CHK=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${JS_TEMPLATE}"'") | .name '`

if [[ "${JS_TPL_CHK}" != "" ]]
then
   echo "Template Name ${JS_TEMPLATE} Already Exists, Exiting ..."
   exit 1
fi

echo "Template Name: ${JS_TEMPLATE}"

#########################################################
## Get database for datasource ...

#echo "Getting Database Source for Jetstream Datasource Reference ..."
STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

DS_NAME_REFS=`echo "${STATUS}" | jq --raw-output '.result[] | select (.provisionContainer != null) | .provisionContainer '`
#echo "DS_NAME_REFS: ${DS_NAME_REFS}"

#FUTURE: use jq arrays for searches???
#DS_ARR=`jq -n --arg inarr "${DS_NAME_REFS}" '{ arr: $inarr | split("\n") } | .arr'`
#echo "${DS_ARR}" | jq "."

DS_NAME="${2}"
if [[ "${DS_NAME}" == "" ]]
then
   ZTMP="Data Source Name"
   if [[ "${DEF_DS_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Valid ${ZTMP}s: [copy-n-paste]"
      while read ref
      do
         echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${ref}"'") | .name'	
      done <<< "${DS_NAME_REFS}"
      echo "Please Enter ${ZTMP}: "
      read DS_NAME
      if [ "${DS_NAME}" == "" ]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      DS_NAME=${DEF_DS_NAME}
   fi
fi

DS_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${DS_NAME}"'") | .reference '`
if [[ "${DS_REF}" == "" ]]
then
   echo "Data Source Reference ${DS_REF} for ${DS_NAME} not found, Exiting ..."
   exit 1
fi

echo "template datasource name: ${DS_NAME}"
echo "template datasource reference: ${DS_REF}"

#########################################################
#
# Get Remaining Command Line Parameters ...
#

JS_DS_NAME="${3}"
if [[ "${JS_DS_NAME}" == "" ]]
then
   ZTMP="Jetstream Data Source Name"
   if [[ "${DEF_JS_DS_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter ${ZTMP}: "
      read JS_DS_NAME
      if [[ "${JS_DS_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_DS_NAME=${DEF_JS_DS_NAME}
   fi
fi

#########################################################
## TODO ## Validate Data Source Object/Names are not already used ...

#STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

#########################################################
## Creating a JetStream Template from an Oracle Database ...

json="
{
     \"type\": \"JSDataTemplateCreateParameters\",
     \"dataSources\": [
         {
             \"type\": \"JSDataSourceCreateParameters\",
             \"source\": {
                 \"type\": \"JSDataSource\",
                 \"priority\": 1,
                 \"name\": \"${JS_DS_NAME}\"
             },
             \"container\": \"${DS_REF}\"
         }
     ],
     \"name\": \"${JS_TEMPLATE}\"
"

echo "JSON: ${json}"

echo "Create JetStream Template ${JS_TEMPLATE} with Data Source DB ${DS_NAME} ..."

STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
}
EOF
`

echo "JetStream Template Creation Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

echo " "
echo "Done ... (no job required for this action)"
echo " "
exit 0


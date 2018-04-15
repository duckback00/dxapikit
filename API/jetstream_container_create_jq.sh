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
# Program Name : jetstream_container_create_jq.sh
# Description  : Delphix API to create a JetStream Container
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.3 2018-03-26
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: 
# ./jetstream_container_create_jq.sh
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
#DEF_JS_TEMPLATE="tpl"           # JetStream Template Name
#DEF_JS_DS_NAME="ds"             # JetStream Template Data Source Name
#DEF_JS_DC_NAME="dc"             # JetStream Data Container Name
#DEF_DS_NAME="VBITT" 	 	 # Database Data Source VDB 
#
# For full interactive option, set default values to nothing ...
#
DEF_JS_TEMPLATE=""
DEF_JS_DS_NAME=""
DEF_JS_DC_NAME=""
DEF_DS_NAME=""

#
FAST_REFRESH="Y"
USERS="[\"delphix_admin\",\"dev\"]"

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
## Get API Version Info ...

APIVAL=$( jqGet_APIVAL )
if [[ "${APIVAL}" == "" ]]
then
   echo "Error: Delphix Engine API Version Value Unknown ${APIVAL} ..."
else
   echo "Delphix Engine API Version: ${APIVAL}"
fi

if [[ $APIVAL -lt 190 ]]
then
   FAST_REFRESH="N"
fi

#########################################################
## Get User Reference(s) ...

#echo "User API "
STATUS=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

###USERS="[\"delphix_admin\",\"dev\"]"
TMP=`echo "$USERS" | jq --raw-output ".[]"`
echo "User Names: ${USERS}"

#
# Process Array using jq ...
#
let i=0
USER_REFS="["
DELIM=""
while read usr
do
   #echo "$i) |${usr}|"
   #let i=i+1
   Z=`echo "${STATUS}" | jq --raw-output ".result[] | select (.name == \"${usr}\") | .reference"`
   if [[ "${Z}" != "" ]]
   then
      USER_REFS="${USER_REFS}${DELIM}\"${Z}\""       # quoted
      #USER_REFS="${USER_REFS}${DELIM}"'\"'${Z}'\"'    # quotes escaped
      DELIM=","
   fi
done <<< "$TMP"
USER_REFS="${USER_REFS}]"
echo "User References: ${USER_REFS}"

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

#JS_ACTIVE_BRANCH_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${JS_TEMPLATE}"'") | .activeBranch '`
#echo "active template branch reference: ${JS_ACTIVE_BRANCH_REF}"

#########################################################
## Get JetStream sourceDataLayout ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

JS_DS_NAME="${2}"
if [[ "${JS_DS_NAME}" == "" ]]
then
   ZTMP="Template Data Source Name"
   if [[ "${DEF_JS_DS_NAME}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
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

#
# Parse ...
#
JS_DATALAYOUT=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_DS_NAME}"'") | .dataLayout '`
echo "JetStream sourceDataLayout: ${JS_DATALAYOUT}"

JS_DS_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_DS_NAME}"'") | .container '`
echo "JetStream data source parent container: ${JS_DS_REF}"

#########################################################
## Get database for container datasource ...

#echo "Getting Database Source for Jetstream Container Datasource Reference ..."
STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

DS_NAME_REFS=`echo "${STATUS}" | jq --raw-output '.result[] | select (.provisionContainer=="'"${JS_DS_REF}"'") | .reference '`
echo "DS_NAME_REFS: ${DS_NAME_REFS}"

DS_NAME="${3}"
if [[ "${DS_NAME}" == "" ]]
then
   ZTMP="Container Data Source Name"
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
      if [[ "${DS_NAME}" == "" ]]
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
   echo "Container Data Source Reference ${DS_REF} for ${DS_NAME} not found, Exiting ..."
   exit 1
fi

echo "container data source name: ${DS_NAME}"
echo "container data source reference: ${DS_REF}"

#########################################################
## Get Remaining Command Line Parameters ...

JS_DC_NAME="${4}"
if [[ "${JS_DC_NAME}" == "" ]]
then
   ZTMP="Jetstream Container Name"
   if [[ "${DEF_JS_DC_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter ${ZTMP}: "
      read JS_DC_NAME
      if [[ "${JS_DC_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      JS_DC_NAME=${DEF_JS_DC_NAME}
   fi
fi

echo "jetstream container name: ${JS_DC_NAME}"

#########################################################
## TODO ## Validate Data Container Object/Names are not already used ...

#########################################################
## Creating a JetStream Container from a Source ...

#
# JSON parameters prior to J ...
#
if [[ $APIVAL -lt 190 ]]
then

   json="{
     \"type\": \"JSDataContainerCreateParameters\",
     \"dataSources\": [
         {
             \"type\": \"JSDataSourceCreateParameters\",
             \"source\": {
                 \"type\": \"JSDataSource\",
                 \"priority\": 1,
                 \"name\": \"${DS_NAME}\"
             },
             \"container\": \"${DS_REF}\"
         }
     ],
     \"name\": \"${JS_DC_NAME}\",
     \"template\": \"${JS_TPL_REF}\",     
     \"timelinePointParameters\": {
         \"type\": \"JSTimelinePointLatestTimeInput\",
         \"sourceDataLayout\": \"${JS_DATALAYOUT}\"  
     }
}
"

elif [[ "${FAST_REFRESH}" != "Y" ]]
then

json="
{
     \"type\": \"JSDataContainerCreateWithRefreshParameters\",
     \"dataSources\": [
         {
             \"type\": \"JSDataSourceCreateParameters\",
             \"source\": {
                 \"type\": \"JSDataSource\",
                 \"priority\": 1,
                 \"name\": \"${DS_NAME}\"
             },
             \"container\": \"${DS_REF}\"
         }
     ],
     \"name\": \"${JS_DC_NAME}\",
     \"template\": \"${JS_TPL_REF}\",
     \"timelinePointParameters\": {
         \"type\": \"JSTimelinePointLatestTimeInput\",
         \"sourceDataLayout\": \"${JS_DATALAYOUT}\"
     }
}
"

else
   #
   # Type Option for API version 190 or later
   # Faster Container Creations ...
   #
json="
{
       \"template\":  \"${JS_TPL_REF}\"
       ,\"owners\": ${USER_REFS} 
       ,\"name\": \"${JS_DC_NAME}\"
       ,\"dataSources\": [{
          \"source\": {
              \"priority\":1
              ,\"name\":\"${DS_NAME}\"
              ,\"type\": \"JSDataSource\"
           }
          ,\"container\": \"${DS_REF}\"
          ,\"type\": \"JSDataSourceCreateParameters\"
        }]
       ,\"properties\": {}
       ,\"type\": \"JSDataContainerCreateWithoutRefreshParameters\"
}
"
   # NOTICE: no timelinePointParameters name: values

fi

echo "JSON: ${json}"

echo "Create JetStream Container ${JS_DC_NAME} with Data Source DB ${DS_NAME} ..."

STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "JetStream Container Creation Results: ${STATUS}"
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


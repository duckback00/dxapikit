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
# Copyright (c) 2019 by Delphix. All rights reserved.
#
# Program Name : replication.sh
# Description  : Delphix API for Replication
# Author       : Alan Bitterman
# Created      : 2019-04-12
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Create a "json" replication specification string later in code
#      use ./replication_objects.sh if necessary to create objects array
#
# Usage: ./replication.sh
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
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## About API Call ...

#echo "About API "
STATUS=`curl -s -X GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo ${STATUS} | jq "."

#
# Get Delphix Engine Build Version ...
#
major=`echo ${STATUS} | jq --raw-output ".result.buildVersion.major"`
minor=`echo ${STATUS} | jq --raw-output ".result.buildVersion.minor"`
micro=`echo ${STATUS} | jq --raw-output ".result.buildVersion.micro"`

let buildval=${major}${minor}${micro}
echo "Delphix Engine Build Version: ${major}${minor}${micro}"
echo " " 

#########################################################
## Replication Specifications ...

GLOBIGNORE="*"

STATUS=`curl -s -X GET -k $BaseURL/replication/spec -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo ${STATUS} | jq "."

echo "Existing Replication Specifications ..."
TMP=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
echo "${TMP}"
echo "---------------------------------------------------"

#########################################################
## Action ...

echo "Enter Action [ list | create | execute | delete ]: "
read ACTION

if [[ "${ACTION}" == "" ]]
then
   echo "No ${ACTION} provided, exiting ... "
   exit 
fi

#########################################################
## Specification Name ...

echo "--------------------------------------------------"
echo "${TMP}"
echo " "
echo "Please Enter Specification Name (case sensitive): "
read SPEC
if [[ "${SPEC}" == "" ]]
then
   echo "No ${SPEC} Provided, Exiting ..."
   exit 1;
fi

SPEC_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SPEC}"'") | .reference '`
if [[ "${ACTION}" != "create" ]]
then
   echo "specification reference: ${SPEC_REF}"
   if [[ "${SPEC_REF}" == "" ]]
   then
      echo "Error: No reference found for ${SPEC} ${SPEC_REF}, Exiting ..."
      exit 1;
   fi
else
   if [[ "${SPEC_REF}" != "" ]]
   then
      echo "specification reference: ${SPEC_REF}"
      echo "Error: Name ${SPEC} exists, please enter a unqiue name. Exiting ..."
      exit 1;
   fi
fi

#########################################################
## List ...

if [[ "${ACTION}" == "list" ]]
then
   GLOBIGNORE="*"
   echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SPEC}"'")'

   objects=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SPEC}"'") | .objectSpecification.objects[]'`
   ###echo "Objects: ${objects}"

   DBSTATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   GRPSTATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`

   #
   # Process Array ...
   #
   grppad='......................'
   dbpad='..............................'
   let i=0
   while read line
   do
      ###echo "$i) |${line}|"
      let i=i+1
      if [[ ${line} == GROUP* ]]
      then
         TMP=`echo "${GRPSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${line}"'") | .name '`
         printf "Group Object: %s %s %s\n" $line "${grppad:${#line}}" "${TMP}"
      else
         TMP=`echo "${DBSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${line}"'") | .name '`
         printf "DB Object: %s %s %s\n" $line "${dbpad:${#line}}" "${TMP}"

      fi
   done <<< "${objects}"

   ## Get Source State ...
   STATUS=`curl -s -X GET -k ${BaseURL}/replication/sourcestate -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   #echo ${STATUS} | jq "."
   echo "Fetching sourcestate serialization point ..."
   SERIAL=`echo "${STATUS}" | jq --raw-output '.result[] | select(.spec=="'"${SPEC_REF}"'") | .lastPoint '` 

   ## Get Serialization Point ...
   STATUS=`curl -s -X GET -k ${BaseURL}/replication/serializationpoint/${SERIAL} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   echo ${STATUS} | jq "."

fi

#########################################################
## Create ...

if [[ "${ACTION}" == "create" ]]
then
   #
   # Specification Template ...
   #
   # To build objects array, use ./replication_objects.sh script ...
   #
   TARGET_HOST="${DMIP}"
   GLOBIGNORE="*"
   json="{
        \"targetHost\":\"${TARGET_HOST}\",
        \"targetPort\":8415,
        \"targetPrincipal\":\"delphix_admin\",
        \"targetCredential\":{
                \"password\":\"delphix\",
                \"type\":\"PasswordCredential\"
        },
        \"objectSpecification\":{
                \"objects\":[\"GROUP-2\",\"APPDATA_CONTAINER-1\",\"APPDATA_CONTAINER-3\"],
                \"type\":\"ReplicationList\"
        },
        \"schedule\":\"0 0 0 * * ?\",
        \"encrypted\":false,
        \"bandwidthLimit\":0,
        \"numberOfConnections\":1,
        \"description\":null,
        \"useSystemSocksSetting\":false,
        \"name\":\"${SPEC}\",
        \"type\":\"ReplicationSpec\"
   }"
   echo "JSON: ${json}"
 
   STATUS=`curl -s -X POST -k --data @- $BaseURL/replication/spec -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

   echo ${STATUS} | jq "."
fi

#########################################################
## Execute ...

if [[ "${ACTION}" == "execute" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/replication/spec/${SPEC_REF}/execute -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

   echo ${STATUS} | jq "."

   RESULTS=$( jqParse "${STATUS}" "status" )

   #########################################################
   ## Get Job Number ...

   JOB=$( jqParse "${STATUS}" "job" )
   echo "Job: ${JOB}"
   jqJobStatus "${JOB}"            # Job Status Function ...

fi

#########################################################
## Delete ...

if [[ "${ACTION}" == "delete" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/replication/spec/${SPEC_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

   echo ${STATUS} | jq "."
fi

############## E O F ####################################
echo " "
echo "Done "
exit 0;

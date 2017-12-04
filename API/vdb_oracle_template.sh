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
# Program Name : vdb_oracle_template.sh
# Description  : Delphix API for vdb oracle init templates
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.1 2017-08-14
#
#
# Requirements:
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#
# Interactive Usage: 
# ./vdb_oracle_template.sh
#
# Non-Interactive Usage: 
# ./vdb_oracle_template.sh [Template_Name] [list|create|update|delete] 
#
# ./vdb_oracle_template.sh [Template_Name] [create] 
#   if Template_Name.ora file exists, it will automatically be read/loaded
#   if Template_Name.ora file does not exist, the editor will be invoked
#
# ./vdb_oracle_template.sh 400M create  if template exists and local init file exist, update will be done automatically
# ./vdb_oracle_template.sh 200M update
# ./vdb_oracle_template.sh 200M list
# ./vdb_oracle_template.sh mine4 delete
#
#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

EDITOR="vi"

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

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
## Get List of Existing Template Names ...

STATUS=`curl -s -X GET -k ${BaseURL}/database/template -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "group: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

#########################################################
#
# Command Line Arguments ...
#

# 
# Get Template Name and reference ...
#
TEMPLATE_NAME="$1"
TEMPLATE_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TEMPLATE_NAME}"'") | .reference '`

#
# If null, then prompt for template name ...
#
if [[ "${TEMPLATE_REF}" == "" ]] && [[ "${TEMPLATE_NAME}" == "" ]]
then
   TEMPLATE_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | .name '`
   echo "Existing Template Names: "
   echo "${TEMPLATE_NAMES}"

   echo "Please Select or Enter New Template Name (case sensitive): "
   read TEMPLATE_NAME
   if [ "${TEMPLATE_NAME}" == "" ]
   then
      echo "No Template Name Provided, Exiting ..."
      exit 1;
   fi
fi;

#
# Check for reference for template name provided ...
#
TEMPLATE_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TEMPLATE_NAME}"'") | .reference '`

#
# Action ...
#
# No Template reference found, create request ...
#
if [ "${TEMPLATE_REF}" == "" ]
then
   echo "New Template Name Provided, Creating ..."
   ACTION="create"
else
   #
   # get action ...
   #
   ACTION=$2
   if [[ "${ACTION}" == "" ]]
   then
      echo "Please Enter Action [list|update|delete] : "
      read ACTION
      if [ "${ACTION}" == "" ]
      then
         echo "No Action Provided, Exiting ..."
         exit 1;
      fi
   fi
fi
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')

if [[ "${ACTION}" != "create" ]] && [[ "${ACTION}" != "update" ]] && [[ "${ACTION}" != "delete" ]] && [[ "${ACTION}" != "list" ]]
then
   echo "ERROR: Invalid Action ${ACTION}, Exiting ..."
   exit 1
fi

#########################################################
## Perform Action ...

echo "database template name: ${TEMPLATE_NAME}"
if [[ "${TEMPLATE_REF}" != "" ]] 
then
   echo "database template reference: ${TEMPLATE_REF}"
fi
echo "Action: ${ACTION}"
EDIT_CHK="N"

#
# Update ...
# 
if [[ "${ACTION}" == "update" ]] 
then
   # 
   # get parameters ...
   #
   echo "${STATUS}" | jq --raw-output ".result[] | select (.reference==\"${TEMPLATE_REF}\") | .parameters "
   PARAMS=`echo "${STATUS}" | jq --raw-output ".result[] | select (.reference==\"${TEMPLATE_REF}\") | .parameters "`
   KEYS=`echo "${PARAMS}" | jq keys`

   # 
   # if template exist locally, make backup copy ...
   #
   if [[ -f "${TEMPLATE_NAME}.ora" ]]
   then
      mv "${TEMPLATE_NAME}.ora" "${TEMPLATE_NAME}.ora_${DT}"
   fi

   # Remove line feeds and square brackets ...
   features=`echo ${KEYS} | tr '\n' ' ' | sed 's/.*\[//;s/\].*//;' | tr -d '"' `

   #
   # Parse String into a shell Array ...
   #
   IFS=,
   ary=($features)
   for key in "${!ary[@]}";
   do
      #echo "$key |${ary[$key]}|";
      #
      # Remove leading and Trailing Spaces ...
      #
      tmp=`echo ${ary[$key]} | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
      #echo "$key |${tmp}|";
      VALUE=`echo "${PARAMS}" | jq --raw-output ".${tmp}"`
      #
      # write out formatted parameters to file ...
      #
      echo "${tmp} = ${VALUE}" >> ${TEMPLATE_NAME}.ora
   done
   IFS=

   echo "local init parameter file written: ${TEMPLATE_NAME}.ora "
   EDIT_CHK="Y"
fi

#
# create ...
#
if [[ "${ACTION}" == "create" ]]
then
   echo "Creating  Template ${TEMPLATE_NAME} ..."
   if [[ ! -f "${TEMPLATE_NAME}.ora" ]] 
   then 
      echo "touching ..."
      touch "${TEMPLATE_NAME}.ora" 
      EDIT_CHK="Y"
   else 
      SIZE=`wc -c < ${TEMPLATE_NAME}.ora`
      if [[ $SIZE -eq 0 ]]
      then
         EDIT_CHK="Y"
      fi
   fi
   if [[ "${TEMPLATE_REF}" != "" ]]
   then
      ACTION="update"
   fi
fi

#
# Get Create or Update Parameters ...
#
SIZE=0
if [[ -f "${TEMPLATE_NAME}.ora" ]] && [[ "${ACTION}" != "delete" ]] && [[ "${ACTION}" != "list" ]]
then

   #
   # Edit Parameter File ...
   #
   if [[ "${EDIT_CHK}" == "Y" ]] 
   then 
      ${EDITOR} "${TEMPLATE_NAME}.ora"
   fi

   # 
   # Read Template File and build JSON for new parameters ...
   #
   NEW_PARAMS="{"
   DELIM=""
   IFS='='
   while read line
   do
      #echo "${line}" 
      arr=($line)
      #echo "Name: ${arr[0]}  Value: ${arr[1]} "
      tmp0=`echo ${arr[0]} | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
      tmp1=`echo ${arr[1]} | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
      NEW_PARAMS="${NEW_PARAMS}${DELIM}  \"${tmp0}\": \"${tmp1}\""
      DELIM=","
   done < "${TEMPLATE_NAME}.ora"
   IFS=
   NEW_PARAMS="${NEW_PARAMS} }"

   echo "${NEW_PARAMS}" | jq "."

   SIZE=`wc -c < ${TEMPLATE_NAME}.ora`
fi

#########################################################
#
# Perform the API per the action ...
#

echo "${ACTION} ${TEMPLATE_NAME} ..."

case ${ACTION} in
list) 

   echo "${STATUS}" | jq --raw-output ".result[] | select (.reference==\"${TEMPLATE_REF}\") | .parameters "

;;
create)

   JSON="{
    \"type\": \"DatabaseTemplate\",
    \"name\": \"${TEMPLATE_NAME}\",
    \"parameters\": ${NEW_PARAMS},
    \"sourceType\": \"OracleVirtualSource\"
}"

   echo "JSON: ${JSON}"

   if [[ $SIZE -gt 0 ]]
   then

      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/template -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${JSON}
EOF
`


   else
      echo "${TEMPLATE_NAME}.ora file has $SIZE bytes, ${ACTION} not performed ..."
   fi

;;
update) 

   JSON="{
    \"type\": \"DatabaseTemplate\",
    \"name\": \"${TEMPLATE_NAME}\",
    \"parameters\": ${NEW_PARAMS},
    \"sourceType\": \"OracleVirtualSource\"
}"

   echo "JSON: ${JSON}"

   if [[ $SIZE -gt 0 ]]
   then

      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/template/${TEMPLATE_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${JSON}
EOF
`


   else
      echo "${TEMPLATE_NAME}.ora file has $SIZE bytes, ${ACTION} not performed ..."
   fi

;;
delete)

   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/template/${TEMPLATE_REF}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`


   if [[ -f "${TEMPLATE_NAME}.ora" ]]
   then
      mv "${TEMPLATE_NAME}.ora" "${TEMPLATE_NAME}.ora_${DT}"
   fi


;;
*)
  echo "Unknown option (create | update | delete): $ACTION"
  echo "Exiting ..."
  exit 1;
;;
esac

#########################################################
#
# Get Results ...
#
RESULTS=$( jqParse "${STATUS}" "status" )
echo "${ACTION} Status: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Check coding ... ${STATUS}"
   echo "Exiting ..."
   exit 1;
fi

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


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
# Program Name : objects.sh
# Description  : Delphix API Replication Objects
# Author       : Alan Bitterman
# Created      : 2019-04-12
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Usage: ./about.sh
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

#STATUS=`curl -s -X GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#########################################################
## Groups ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq -r "."

TMP=`echo "${STATUS}" | jq -r ".result[] | select (.namespace==null) | .name"`

GRP=""
ARR=""
DELIM=""
while true; do
   echo "Which Group do you want to Replicate?"
   echo "${TMP}"
   echo
   echo -n "Enter Group: "
   read topic
   if [[ "${topic}" == "" ]]
   then 
      break
   fi
   GROUP_REF=`echo "${STATUS}" | jq -r ".result[] | select (.name==\"${topic}\" and .namespace==null) | .reference"`
   GRP="${GRP}${DELIM}\"${topic}\""
   ARR="${ARR}${DELIM}\"${GROUP_REF}\""
   echo "Groups Selected: [ ${GRP} ]"
   #echo "${ARR}"
   if [[ "${GROUP_REF}" != "" ]]
   then
      DELIM=","
   fi
done
echo " "
echo "Groups Array: [${ARR}]"
echo "--------------------------------------------"

#########################################################
## Databases ...

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`

DB=""
DBDELIM=""
for i in ${ARR//,/ }
do
   GRP=`echo "$i" | tr -d '"'`
   #echo "$i  $GRP"
   TMP=`echo "${STATUS}" | jq -r ".result[] | select (.group==\"${GRP}\" and .namespace==null) | .name"`
   while true; do
      echo "Which Database do you want to Replicate?"
      echo "${TMP}"
      echo
      echo -n "Enter Database: "
      read topic
      if [[ "${topic}" == "" ]]
      then
         break
      fi
      DB_REF=`echo "${STATUS}" | jq -r ".result[] | select (.name==\"${topic}\" and .namespace==null) | .reference"`
      if [[ "${DB}" != "" ]]
      then
         DBDELIM=","
      fi
      DB="${DB}${DBDELIM}\"${topic}\""
      ARR="${ARR}${DELIM}\"${DB_REF}\""
      #echo "${GRP}"
      echo "Databases Selected: [ ${DB} ]"
      #echo "${ARR}"
      if [[ "${DB_REF}" != "" ]]
      then
         DBDELIM=","
      fi
   done
done
echo " " 
echo "Replication Objects Array: [${ARR}]"
echo "[${ARR}]" | sed 's/\"/\\"/g'

#########################################################
## The End is Here ...
echo " "
echo "Done ... "
exit 0

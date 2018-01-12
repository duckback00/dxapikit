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
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Program Name : jetstream_container_users_jq.sh
# Description  : Delphix API to get Users per JetStream Container(s)
# Author       : Alan Bitterman
# Created      : 2018-01-11
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: 
# ./jetstream_container_users_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

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
#else
#   echo "Delphix Engine API Version: ${APIVAL}"
fi

#########################################################
## Get User and Authorization Lists  ...

#echo "Users "
USERLIST=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${USERLIST}" "status" )

AUTHLIST=`curl -s -X GET -k ${BaseURL}/authorization -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${AUTHLIST}" "status" )

#########################################################
## Get JetStream Containers  ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

CONTAINER_REFS=`echo ${STATUS} | jq --raw-output ".result[].reference"`
#echo "CONTAINER_REFS: ${CONTAINER_REFS}"

#########################################################
## Process Arrays using jq ...

fill='                        '
while read CONTAINER_REF
do
   #echo "x.) |${CONTAINER_REF}|"
   CONTAINER_NAME=`echo ${STATUS} | jq --raw-output ".result[] | select (.reference == \"${CONTAINER_REF}\") | .name"`
   USER_REFS=`echo "${AUTHLIST}" | jq --raw-output ".result[] | select (.target == \"${CONTAINER_REF}\") | .user"`
   echo "-----------------------------------------------"
   z="Container Reference :"
   printf "%s %s %s\n" "${fill:${#z}}" "${z}" "${CONTAINER_REF}"
   z="Container Name :"
   printf "%s %s %s\n" "${fill:${#z}}" "${z}" "${CONTAINER_NAME}"

   while read USER_REF
   do
      USER_NAME=`echo "${USERLIST}" | jq --raw-output ".result[] | select (.reference == \"${USER_REF}\") | .name"`
      usr="User :" 
      printf "%s %s %s\n" "${fill:${#usr}}" "${usr}" "${USER_NAME}"
    done <<< "${USER_REFS}"

done <<< "${CONTAINER_REFS}"


############## E O F ####################################
echo "Done ..."
echo " "
exit 0


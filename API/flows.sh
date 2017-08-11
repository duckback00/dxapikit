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
# Program Name : flows.sh
# Description  : Delphix API timeflows examples
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Include ./jqJSON_subroutines.sh
#  3.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Interactive Usage: ./flows.sh
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
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Command Line Arguments ...
#
SOURCE_SID=$1
if [[ "${SOURCE_SID}" == "" ]]
then

   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
   echo "VDB Names:"
   echo "${VDB_NAMES}"
   echo " "

   echo "Please Enter dSource or VDB Name: "
   read SOURCE_SID
   if [ "${SOURCE_SID}" == "" ]
   then
      echo "No dSource of VDB Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export SOURCE_SID

echo "Source: ${SOURCE_SID}"

CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## List timeflows for the container reference

echo " "
echo "Timeflows API "
STATUS=`curl -s -X GET -k ${BaseURL}/timeflow -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#########################################################
## Select the timeflow  

FLOW_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .name '`
echo "timeflow names:"
echo "${FLOW_NAMES}"
echo " "
echo "Select timeflow Name (copy-n-paste from above list): "
read FLOW_NAME
if [ "${FLOW_NAME}" == "" ]
then
   echo "No Flow Name provided, exiting ... ${FLOW_NAME} "
   exit 1;
fi


# Get timeflow reference ...
FLOW_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME}"'") | .reference '`
echo "timeflow reference: ${FLOW_REF}"

# timeflowRanges for this timeflow ...
echo " "
echo "TimeflowRanges for this timeflow ... "
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/timeflow/${FLOW_REF}/timeflowRanges -b "${COOKIE}" -H "${CONTENT_TYPE}" <<-EOF
{
    "type": "TimeflowRangeParameters"
}
EOF
`

echo ${STATUS} | jq "."

#########################################################
## Get snapshot for this timeflow ...

echo " "
echo "Snapshot per Timeflow ... "
STATUS=`curl -s -X GET -k ${BaseURL}/snapshot -b "${COOKIE}" -H "${CONTENT_TYPE}"`
SYNC_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .timeflow=="'"${FLOW_REF}"'") | .name '`
echo "snapshots:"
echo "${SYNC_NAMES}"
echo " "
echo "Select Snapshot Name (copy-n-paste from above list): "
read SYNC_NAME
if [ "${SYNC_NAME}" == "" ]
then
   echo "No Snapshot Name provided, exiting ... ${SYNC_NAME} "
   exit 1;
fi

SYNC_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SYNC_NAME}"'") | .reference '`
echo "snapshot reference: ${SYNC_REF}"

echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SYNC_NAME}"'") '


echo " "
echo "Done "
exit 0;


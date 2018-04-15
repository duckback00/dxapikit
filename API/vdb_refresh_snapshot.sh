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
# Program Name : vdb_refresh_snapshot.sh
# Description  : Delphix API Refresh VDB by Timeflow Snapshot
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage: ./vdb_refresh_snapshot.sh
#
# Delphix Docs Reference:
#   https://docs.delphix.com/docs/reference/web-service-api-guide/api-cookbook-common-tasks-workflows-and-examples
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################

#
# Command Line Arguments ...
#
SOURCE_SID=$1
if [[ "${SOURCE_SID}" == "" ]]
then
   echo "Please Enter VDB Name (case sensitive): "
   read SOURCE_SID
   if [ "${SOURCE_SID}" == "" ]
   then
      echo "No dSource of VDB Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export SOURCE_SID

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

echo "Source: ${SOURCE_SID}"

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "database container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get provision source database container

STATUS=`curl -s -X GET -k ${BaseURL}/database/${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#echo "${STATUS}"
PARENT_SOURCE=`echo ${STATUS} | jq --raw-output '.result | select(.reference=="'"${CONTAINER_REFERENCE}"'") | .provisionContainer '`
echo "provision source container: ${PARENT_SOURCE}"

#########################################################
## List timeflows for the container reference

echo " "
echo "Timeflows API "
STATUS=`curl -s -X GET -k ${BaseURL}/timeflow -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}"

#########################################################
## Select the timeflow

FLOW_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select(.container=="'"${PARENT_SOURCE}"'") | .name '`
echo "Timeflow Names:"
echo "${FLOW_NAMES}"
echo " "
echo "Select Timeflow Name (copy-n-paste from above list): "
read FLOW_NAME
if [ "${FLOW_NAME}" == "" ]
then
   echo "No Flow Name provided, exiting ... ${FLOW_NAME} "
   exit 1;
fi

# Get timeflow reference ...
FLOW_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME}"'") | .reference '`
echo "Timeflow Reference: ${FLOW_REF}"

#########################################################
## Get snapshot for this timeflow ...

echo " "
echo "Snapshot per Timeflow ... "
STATUS=`curl -s -X GET -k ${BaseURL}/snapshot -b "${COOKIE}" -H "${CONTENT_TYPE}"`
SYNC_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select(.container=="'"${PARENT_SOURCE}"'" and .timeflow=="'"${FLOW_REF}"'") | .name '`
echo "Snapshots:"
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

#
# Build JSON String ...
#
json="{
    \"type\": \"OracleRefreshParameters\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSnapshot\",
        \"snapshot\": \"${SYNC_REF}\"
    }
}"

echo "json> ${json}"
echo "Please wait, Submitting Refresh Job Request ..."

#
# Submit VDB operations request ...
#
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/${CONTAINER_REFERENCE}/refresh -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

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
exit 0;


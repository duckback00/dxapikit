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
# Program Name : jetstream_create_branch_from_bookmark_jq.sh
# Description  : Delphix API to create Container Branch from Bookmark
# Author       : Alan Bitterman
# Created      : 2017-09-29
# Version      : v1.1
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: ./jetstream_create_branch_from_bookmark_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#
# Container Name and Branch Name Required  ...
#
DC_NAME="jsdc"                  # Data Container Name ...

BRANCH_NAME="Branch_${DT}"      # New Branch Name ...

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
## Get container ...

#echo "Getting Container Reference Value ..."
STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "." 

#
# Parse out container reference for name of ${DC_NAME} ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DC_NAME}"'") | .reference '`
echo "Container Reference: ${CONTAINER_REFERENCE}"

ACTIVE_BRANCH=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DC_NAME}"'") | .activeBranch '`
echo "Active Branch Reference: ${ACTIVE_BRANCH}"

#########################################################
## Get Branches ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

#
# Parse ...
#
echo " "
BRANCH_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | select(.dataLayout=="'"${CONTAINER_REFERENCE}"'") | .name +","+ .reference '`
#echo "Branch Names for ${DC_NAME}: ${BRANCH_NAMES}"

#
# List Branch Names and Object References ...
#
printf "%-44s | %s\n" "REFERENCE" "BRANCH_NAME" 
echo "---------------------------------------------+-----------------"
while read info
do
   IFS=,
   arr=($info)
   ###echo "Writing Results for Table: ${arr[0]}    id: ${arr[1]}"
   TMP_NAME="${arr[0]}"
   TMP_REF="${arr[1]}"
   if [[ "${ACTIVE_BRANCH}" == "${TMP_REF}" ]] 
   then
      printf "[Active] %-35s : %s\n" ${TMP_REF}  ${TMP_NAME}
   else
      printf "%-44s : %s\n" ${TMP_REF}  ${TMP_NAME}
   fi
done <<< "${BRANCH_NAMES}"
IFS=

#
# Get user provided branch name or exit ...
# 
echo "Select Branch Name that contains Bookmark, Copy-n-Paste Branch Name or return to exit: "
read BOOKMARK_BRANCH_NAME

if [[ "${BOOKMARK_BRANCH_NAME}" == "" ]]
then
   echo "No Branch Name Provided, Exiting ..."
   exit 1;
fi

#
# Get Branch Reference ...
#
BRANCH_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${BOOKMARK_BRANCH_NAME}"'" and .dataLayout=="'"${CONTAINER_REFERENCE}"'") | .reference '`

#
# Validate ...
#
if [[ "${BRANCH_REF}" == "" ]] 
then
   echo "No Bookmark Branch Name/Reference ${BOOKMARK_BRANCH_NAME}/${BRANCH_REF} found, exiting ..."
   exit 1;
fi

echo "Bookmark Branch Reference: ${BRANCH_REF}"

#########################################################
## Get BookMarks per Branch Option ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

echo " "
BM_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .branch=="'"${BRANCH_REF}"'") | .name +","+ .reference '`
echo "Bookmark Names:"
#echo "${BM_NAMES}"

#
# List Bookmark Names and Object References ...
#
printf "%-44s | %s\n" "REFERENCE" "BOOKMARK_NAME"
echo "---------------------------------------------+-----------------"
while read info
do
   IFS=,
   arr=($info)
   ###echo "Writing Results for Table: ${arr[0]}    id: ${arr[1]}"
   TMP_NAME="${arr[0]}"
   TMP_REF="${arr[1]}"
   printf "%-44s : %s\n" ${TMP_REF}  ${TMP_NAME}
done <<< "${BM_NAMES}"
IFS=

#
# Get user provided branch name or exit ...
#
echo "Select Bookmark Name, Copy-n-Paste Bookmark Name or return to exit: "
read BOOK_NAME

if [[ "${BOOK_NAME}" == "" ]]
then
   echo "No Bookmark Name Provided, Exiting ..."
   exit 1;
fi

BOOK_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .branch=="'"${BRANCH_REF}"'" and .name=="'"${BOOK_NAME}"'") | .reference '`

echo "Bookmark Reference: ${BOOK_REF}"

#########################################################
## Create Branch Options ...

# Create Branch using Latest Timestamp ...
# Create Branch using specified Timestamp ...
#
# Create Branch using Bookmark ...
#
#=== POST /resources/json/delphix/jetstream/branch ===
json="{
    \"type\": \"JSBranchCreateParameters\",
    \"dataContainer\": \"${CONTAINER_REFERENCE}\",
    \"name\": \"${BRANCH_NAME}\",
    \"timelinePointParameters\": {
        \"type\": \"JSTimelinePointBookmarkInput\",
        \"bookmark\": \"${BOOK_REF}\"
    }
}
"

echo "$json"

#########################################################
## Creating Branch ...

echo "Creating Branch ${BRANCH_NAME} ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "Create Branch Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

#########################################################
#
# Get Job Number ...
#
JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

#########################################################
#
# Job Information ...
#
JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${JOB_STATUS}" "status" )

#########################################################
#
# Get Job State from Results, loop until not RUNNING  ...
#
JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
while [ "${JOBSTATE}" == "RUNNING" ]
do
   echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
   sleep ${DELAYTIMESEC}
   JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
   PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
done

#########################################################
##  Producing final status

if [ "${JOBSTATE}" != "COMPLETED" ]
then
   echo "Error: Delphix Job Did not Complete, please check GUI ${JOB_STATUS}"
#   exit 1
else 
   echo "Job: ${JOB} ${JOBSTATE} ${PERCENTCOMPLETE}% Completed ..."
fi

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


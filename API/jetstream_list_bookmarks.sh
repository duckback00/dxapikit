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
# Program Name : jetstream_list_bookmarks_jq.sh
# Description  : Delphix API to list Self-Service Container Bookmarks
# Author       : Alan Bitterman
# Created      : 2017-09-25
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: ./jetstream_list_bookmarks_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for JetStream Self-Service Container ...
#
DC_NAME="jsdc"                  # Data Container Name ...

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#Parameter Initialization

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
## Get Container ...

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
# List Branch References and Names ...
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
echo "Enter Branch Name, Copy-n-Paste Branch Name or return to exit: "
read BRANCH_NAME

#
# Get Branch Name from Reference ...
#
BRANCH_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${BRANCH_NAME}"'" and .dataLayout=="'"${CONTAINER_REFERENCE}"'") | .reference '`

#
# Validate ...
#
if [[ "${BRANCH_REF}" == "" ]]
then
   echo "No Branch Name/Reference ${BRANCH_NAME}/${BRANCH_REF} found, Exiting ..."
   exit 1;
fi

echo "Branch Reference: ${BRANCH_REF}"

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
# List Bookmarks and Object References ...
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
# Get user provided branch Reference or exit ...
#
echo "Select Bookmark Name to List, Copy-n-Paste Bookmark Name or return to exit: "
read BOOK_NAME

#
# Get Bookmark Reference ...
#
BOOK_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .branch=="'"${BRANCH_REF}"'" and .name=="'"${BOOK_NAME}"'") | .reference '`

#
# Validate ...
#
if [[ "${BOOK_REF}" == "" ]]
then
   echo "No Bookmark Name/Reference ${BOOK_NAME}/${BOOK_REF} found, Exiting ..."
   exit 1;
fi

echo "Bookmark Reference: ${BOOK_REF}"

#########################################################
## List Bookmark ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/bookmark/${BOOK_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
echo "${STATUS}" | jq "."

#########################################################
## Delete Bookmark ...

echo "Do you want DELETE this Bookmark? [yes/NO] "
read ANS

if [[ "${ANS}" == "yes" ]]
then

   echo "Delete Bookmark ${BOOK_REF} ..."

   STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/bookmark/${BOOK_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

   echo "Delete Bookmark Results: ${STATUS}"
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
   echo " "

fi   	# end if yes to delete ...

############## E O F ####################################
echo "Done ..."
echo " "
exit 0


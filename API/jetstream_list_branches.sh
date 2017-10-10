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
# Program Name : jetstream_list_branches_jq.sh
# Description  : Delphix API to list, delete &/or activate Container Branches
# Author       : Alan Bitterman
# Created      : 2017-09-25
# Version      : v1.1
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: ./jetstream_list_branches_jq.sh
# ... or ...
# ./jetstream_list_branches_jq.sh activate default
# ./jetstream_list_branches_jq.sh delete branch_123
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for Container ...
#
DC_NAME="jsdc"                    # Data Container Name ...

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
#
# Command Line Arguments ...
#
# $1 = activate | delete

ACTION=$1
if [[ "${ACTION}" == "" ]]
then
   echo "Usage: ./jetstream_list_branches.sh [activate | delete] [Branch_Name] "
   echo "---------------------------------"
   echo "activate | delete"
   echo "Please Enter Branch Option : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
fi
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
if [[ "${ACTION}" != "activate" ]] && [[ "${ACTION}" != "delete" ]] 
then
   echo "Unknown Action ${ACTION}, please enter activate or delete, exiting ..."
   exit 1;
fi

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
echo "${STATUS}" | jq "."

#
# Parse ...
#
BRANCH_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | select(.dataLayout=="'"${CONTAINER_REFERENCE}"'") | .name +","+ .reference '`
#echo "Branch Names for ${DC_NAME}: ${BRANCH_NAMES}"

#
# Command Line Arguement 2, Branch Name ...
#
BRANCH_NAME="$2"
if [[ "${BRANCH_NAME}" == "" ]]
then

   #
   # List Branches and Object References ...
   #
   echo " "
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
   echo "${ACTION} Branch, Copy-n-Paste Branch Name or return to exit: "
   read BRANCH_NAME

   if [[ "${BRANCH_NAME}" == "" ]]
   then
      echo "No Branch Name provided, Exiting ..."
      exit 1;
   fi

fi   		# end if BRANCH_NAME != ""

# 
# Get Branch Reference ...
#
BRANCH_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.dataLayout=="'"${CONTAINER_REFERENCE}"'" and .name=="'"${BRANCH_NAME}"'") | .reference '`

#
# Check / Validate BRANCH Reference ...
#
if [[ "${BRANCH_REF}" == "" ]]
then
   echo "No Branch Name/Reference ${BRANCH_NAME}/${BRANCH_REF} found to ${ACTION}, Exiting ..."
   exit 1;
elif [[ "${BRANCH_REF}" == "${ACTIVE_BRANCH}" ]]
then
   echo "${BRANCH_NAME} Branch is Active, unable to ${ACTION}, Exiting ..." 
   exit 1; 
fi

#########################################################
## Perform Action on Branch ...

echo "${ACTION} ${BRANCH_NAME} Branch Reference ${BRANCH_REF} ..."

if [[ "${ACTION}" == "activate" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch/${BRANCH_REF}/activate -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

elif [[ "${ACTION}" == "delete" ]]
then
   STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/branch/${BRANCH_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

else
   echo "Unknown Action: ${ACTION}, nothing executed ..."
   exit 0;
fi


echo "${ACTION} Branch Results: ${STATUS}"
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


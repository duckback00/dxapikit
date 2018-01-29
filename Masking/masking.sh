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
# Program Name : masking.sh
# Description  : Delphix Masking API to execute a Masking Job Id
# Author       : Alan Bitterman
# Created      : 2018-01-30
# Version      : v1.0
#
# Requirements :
#  1.) Delphix Masking Version 5.2 or later!
#  2.) curl and jq command line libraries
#  3.) Populate Delphix Masking Connection Information . ./masking_engine.conf
#  4.) Change any option values below as required
#
# Usage: 
# ./masking.sh [job_number]
#
#########################################################
#                   DELPHIX CORP                        #
#########################################################
#
# Debug ...
#
#set -x 
start_time=`date +%s`

#########################################################
## Delphix Masking Parameter Initialization ...

. ./masking_engine.conf

SHOW_TIMINGS=""     # "Yes" or "" 

#########################################################
##        NO CHANGES REQUIED BELOW THIS LINE           ##
#########################################################

#
# Command Line Arguments ...
#
JOBID=${1}
echo "Job Number: ${JOBID}"

if [[ "${JOBID}" == "" ]]
then
   echo "No Job Id provided, exiting ..."
   exit 1
fi

#########################################################
## File Pre-Processing ...
#########################################################
start_pre=`date +%s`

#
# Any file pre-processing code/logic goes here ..
#

end_pre=`date +%s`
#########################################################
## Authentication ...
start_mask=`date +%s`

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#########################################################
## Execute Masking Job ...

echo "Running Masking JobID ${JOBID} ..."
STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: ${KEY}" -d "{ \"jobId\": ${JOBID} }" "${DMURL}/executions"`
#echo ${STATUS} | jq "."
EXID=`echo "${STATUS}" | jq --raw-output ".executionId"`
echo "Execution Id: ${EXID}"

#########################################################
## Monitor Job Status ...

JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
echo "Job Status: ${JOBSTATUS}"
sleep 1
while [[ "${JOBSTATUS}" == "RUNNING" ]]
do
   STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/executions/${EXID}"`
   #echo ${STATUS} | jq "."
   JOBSTATUS=`echo "${STATUS}" | jq --raw-output ".status"`
   #echo "Current status as of" $(date) " : "  ${JOBSTATUS}
   printf "."
   sleep ${DELAYTIMESEC}   
done
printf "\n"

if [[ "${JOBSTATUS}" != "SUCCEEDED" ]]
then
   echo "Job Error: $JOBSTATUS ... $STATUS"
else
   echo "Masking Job Completed: $JOBSTATUS"
   echo ${STATUS} | jq "."

fi

end_mask=`date +%s`
#####################################################
## Masked File Post-Processing ...
start_post=`date +%s`

#
# Add any post-processing code/logic here ...
#

end_post=`date +%s`
############## E O F ####################################
end_time=`date +%s`

if [[ "${SHOW_TIMINGS}" != "" ]]
then
   echo "overall execution time was `expr $end_time - $start_time` s."
   echo "pre processing time was `expr $end_pre - $start_pre` s."
   echo "masking processing time was `expr $end_mask - $start_mask` s."
   echo "post processing time was `expr $end_post - $start_post` s"
fi

echo " "
echo "Done ..."
echo " "
exit 0

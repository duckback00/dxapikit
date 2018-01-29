#!/bin/bash
#######################################################################
# Filename: masking
# Version: v1.0
# Date: 2018-01-30
# Last Updated: 2018-01-30 Bitt...
# Author: Alan Bitterman
#
# Description: Demo script for executing a masking or profile job
#
# Usage: 
# ./masking.sh [job_number]
#
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
## Delphix Masking Parameter Initialization

DMIP=172.16.160.195
DMPORT=8282
DMUSER="Axistech"
DMPASS="Axis_123"
DMURL="http://${DMIP}:${DMPORT}/masking/api"
DELAYTIMESEC=10
DT=`date '+%Y%m%d%H%M%S'`

SHOW_TIMINGS=""     # "Yes" or "" 

#########################################################
##        NO CHANGES REQUIED BELOW THIS LINE           ##
#########################################################

#
# Command Line Arguments ...
#
JOBID=${1}
echo "Job Number: ${JOBID}"

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

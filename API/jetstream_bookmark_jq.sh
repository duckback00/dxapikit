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
# Program Name : jetstream_bookmark_jq.sh 
# Description  : Delphix API to create a JetStream Bookmark 
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
# Usage: ./jetstream_bookmark_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for JetStream Bookmark ...
#
JS_BRANCH="default"      # JetStream Branch 
BM_NAME="wally_${DT}"    # JetStream Bookmark Name_append timestamp
SHARED="false"           # Share Bookmark true/false
TAGS='"API","Created"'   # Tags Array Values 

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
## Get Branch Reference ...

echo "Getting Jetstream Branch Reference Value ..."

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse ...
#
JS_BRANCH_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_BRANCH}"'") | .reference '`
echo "branch reference: ${JS_BRANCH_REF}"

JS_DATA_CONTAINER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_BRANCH}"'") | .dataLayout '`
echo "dataLayout container reference: ${JS_DATA_CONTAINER}"

#########################################################
# 
# Create Bookmark ...
#  Change parameters as required and desired :) 
#
STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "JSBookmarkCreateParameters",
    "bookmark": {
        "type": "JSBookmark",
        "name": "${BM_NAME}",
        "branch": "${JS_BRANCH_REF}",
        "shared": ${SHARED},
        "tags": [ ${TAGS} ]
    },
    "timelinePointParameters": {
        "type": "JSTimelinePointLatestTimeInput",
        "sourceDataLayout": "${JS_DATA_CONTAINER}"
    }
}
EOF
`

#
# Note: the timelinePointParameters type "JSTimelinePointLatestTimeInput" is the last point / latest time in the branch!
#

#echo "JetStream Bookmark Creation Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

sleep 2

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


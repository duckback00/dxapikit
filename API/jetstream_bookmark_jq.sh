#!/bin/bash

# Create JetStream bookmarks via the API's.

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

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

echo "Authenticating on ${BaseURL}"

#########################################################
## Session and Login ...

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


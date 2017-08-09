#!/bin/bash
#v1.1
#
# sample script to perform basic operations on a  VDB.
#
# Delphix Docs Reference:
#   https://docs.delphix.com/display/DOCS/API+Cookbook%3A+Refresh+VDB
#
#
#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
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
# Authentication ...
#

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
   echo "No Timeflow Name provided, exiting ... ${FLOW_NAME} "
   exit 1;
fi

# Get timeflow reference ...
FLOW_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME}"'") | .reference '`
echo "Timeflow Reference: ${FLOW_REF}"

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

echo " "
echo "Enter Location, SCN# or LSN#, between Start and End Point values (exclude quotes): "
read SCN 
if [ "${SCN}" == "" ]
then
   echo "No Location, SCN# or LSN#, provided, exiting ... ${SCN} "
   exit 1;
fi


json="{
    \"type\": \"OracleRefreshParameters\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointLocation\",
        \"location\": \"${SCN}\",
        \"timeflow\": \"${FLOW_REF}\"
    }
}"

echo "json> ${json}"

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

if [ "${JOB}" != "" ] 
then

#########################################################
#
# Job Information ...
#
JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${JOB_STATUS}" "status" )
#echo "json> $JOB_STATUS"

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


fi     # end if $JOB

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


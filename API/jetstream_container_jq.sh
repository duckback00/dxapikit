#!/bin/bash
#v1.x

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
# Required for JetStream Container ...
#
TPL_NAME="jstpl"                  # JetStream Template Name
DS_NAME="jsds"                    # JetStream Data Source Name 

DC_NAME="jsdc"                    # JetStream Data Container Name
DC_VDB="VBITT2"                   # JetStream Data Container VDB

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
## Get database container

echo "Getting Database Container Reference Value ..."

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out container reference for name of ${DC_VDB} ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DC_VDB}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get JetStream Template ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse ...
#
JS_TEMPLATE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TPL_NAME}"'") | .reference '`
echo "JetStream Data Template: ${JS_TEMPLATE}"

#########################################################
## Get JetStream sourceDataLayout ...

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse ...
#
JS_DATALAYOUT=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DS_NAME}"'") | .dataLayout '`
echo "JetStream sourceDataLayout: ${JS_DATALAYOUT}"

#########################################################
## Creating a JetStream Container from an Oracle Database ...

echo "Create JetStream Container ${DC_NAME} with Data Source DB ${DC_VDB} ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
     "type": "JSDataContainerCreateParameters",
     "dataSources": [
         {
             "type": "JSDataSourceCreateParameters",
             "source": {
                 "type": "JSDataSource",
                 "priority": 1,
                 "name": "${DC_VDB}"
             },
             "container": "${CONTAINER_REFERENCE}"
         }
     ],
     "name": "${DC_NAME}",
     "template": "${JS_TEMPLATE}",     
     "timelinePointParameters": {
         "type": "JSTimelinePointLatestTimeInput",
         "sourceDataLayout": "${JS_DATALAYOUT}"  
     }
}
EOF
`

echo "JetStream Data Container Creation Results: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

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


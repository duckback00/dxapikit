#!/bin/bash
#v1.x

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#########################################################
#         USER VALUES CHANGES REQUIRED BELOW            #
#########################################################
#
# Required for Povisioning Virtual Database ...
#
SOURCE_SID="delphixdb"           # dSource name used to get db container reference value

VDB_NAME="Vdelphixdb"            # Delphix VDB Name
DELPHIX_GRP="ASE_Targets"        # Delphix Engine Group Name

TARGET_ENV="Linux Source"        # Target Environment used to get repository reference value 
TARGET_REP="LINUXSOURCE"         # Target Environment Repository / Instance name

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
## Get or Create Group 

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get Environment reference  

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference information for name of $TARGET_ENV ...
# 
ENV_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TARGET_ENV}"'") | .reference '`
ENV_REFERENCE_HOST=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${TARGET_ENV}"'") | .host '`
echo "env reference: ${ENV_REFERENCE}"
echo "env reference host: ${ENV_REFERENCE_HOST}"

#########################################################
## Get Repository reference  

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Repository Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out reference for name of $ENV_REFERENCE ...
# 
REP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .instanceName=="'"${TARGET_REP}"'") | .reference '`
echo "Source repository reference: ${REP_REFERENCE}"

#########################################################
## Provision a SQL Server Database ...

echo "Provisioning VDB from Source Database ..."

json="{
    \"type\": \"ASEProvisionParameters\",
    \"container\": {
        \"type\": \"ASEDBContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\"
    },
    \"source\": {
        \"type\": \"ASEVirtualSource\",
        \"allowAutoVDBRestartOnHostReboot\": false
    },
    \"sourceConfig\": {
        \"type\": \"ASESIConfig\",
        \"repository\": \"${REP_REFERENCE}\",
        \"databaseName\": \"${VDB_NAME}\",
        \"instance\": {
            \"type\": \"ASEInstanceConfig\",
            \"host\": \"${ENV_REFERENCE_HOST}\"
        }
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\",
        \"location\": \"LATEST_SNAPSHOT\"
    },
    \"truncateLogOnCheckpoint\": false
}"

echo "Provisioning json=$json"

echo "Provisioning VDB from Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

#echo "Provision: ${STATUS}"
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


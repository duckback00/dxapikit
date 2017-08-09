#!/bin/bash
#v1.x

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#
# Required for Database Link and Sync ...
#
DELPHIX_NAME="orcl"               # Delphix dSource Name
DELPHIX_GRP="Oracle Source"       # Delphix Group Name

SOURCE_ENV="Linux Source"         # Source Enviroment Name
SOURCE_SID="orcl"                 # Source Environment Database SID
DB_USER="delphixdb"               # Source Database SID user account
DB_PASS="delphixdb"               # Source Database SID user password

#
# Optional: Source Policy ...
#
# Delphix5150HWv8 database link linkData sourcingPolicy *> set logsyncMode= [ ARCHIVE_ONLY_MODE  ARCHIVE_REDO_MODE  UNDEFINED ]
#
SOURCE_POLICY="        ,\"sourcingPolicy\": {
            \"type\": \"OracleSourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": true,
            \"logsyncInterval\": 5,
            \"logsyncMode\": \"ARCHIVE_REDO_MODE\"
        }
"
# or don't set it by uncommenting the next line ...
# SOURCE_POLICY=""

#
# Optional: Add if default SnapSync Policy is None ...
#
# LINK_NOW="       , \"linkNow\": true"
LINK_NOW=""

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

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
# Parse out group reference for name ${DELPHIX_GRP} ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
## Get sourceconfig

STATUS=`curl -s -X GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out sourceconfig reference for name of $SOURCE_SID ...
#
SOURCE_CFG=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Get Environment primaryUser  

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

# 
# Parse out primaryUser for name of $SOURCE_ENV ...
# 
PRIMARYUSER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_ENV}"'") | .primaryUser '`
echo "primaryUser reference: ${PRIMARYUSER}"

#########################################################
## Link Source Database ...

echo "Linking Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/link -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LinkParameters",
    "group": "${GROUP_REFERENCE}",
    "linkData": {
        "type": "OracleLinkData",
        "config": "${SOURCE_CFG}",
        "dbCredentials": {
            "type": "PasswordCredential",
            "password": "${DB_PASS}"
        },
        "dbUser": "${DB_USER}",
        "environmentUser": "${PRIMARYUSER}"
${SOURCE_POLICY}
${LINK_NOW}
    },
    "name": "${DELPHIX_NAME}"
}
EOF
`

#echo "Database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Fast Job, allow to finish before while ...
#
sleep 2

#
# Get Database Container Value ...
#
CONTAINER=$( jqParse "${STATUS}" "result" )
echo "Container: ${CONTAINER}"

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

#########################################################
#
# sync snapshot ...
#
echo "Running SnapSync ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/${CONTAINER}/sync -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "OracleSyncParameters"
}
EOF
`

#echo ${STATUS}
# {"type":"OKResult","status":"OK","result":"","job":"JOB-49","action":"ACTION-232"}
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
while [ "${JOBSTATE}" == "RUNNING" ] 
do
   echo "Current status as of" $(date) ": ${JOBSTATE} : ${PERCENTCOMPLETE}% Completed"
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


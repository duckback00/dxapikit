#!/bin/bash
#v1.x

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
# Parameter Initialization

. ./delphix_engine.conf

#########################################################
#         USER VALUES CHANGES REQUIRED BELOW            #
#########################################################
#
# Required for Database Link and Sync ...
#
DELPHIX_NAME="delphixdb"           # Delphix dSource Name
DELPHIX_GRP="ASE_Sources"          # Delphix Group Name

SOURCE_ENV="Linux Source"          # Source Enviroment Name
SOURCE_INSTANCE="LINUXSOURCE"      # Source Database Oracle Home or SQL Server Instance Name
SOURCE_SID="delphixdb"             # Source Environment Database SID
SOURCE_DB_USER="sa"           # Source Database user account
SOURCE_DB_PASS="delphix"           # Source Database user password

STAGE_ENV="Linux Source"           # Staging Environment   
STAGE_INSTANCE="LINUXSOURCE"       # Staging Instance

BACKUPPATH="/u02/app/sybase/back"  # Source Load Backup Path 

#
# linkData.syncParameters Value must be one of: 
#  Delphix5140HWv8 database link linkData.syncParameters *> set type=
#  ASELatestBackupSyncParameters    ASENewBackupSyncParameters       ASESpecificBackupSyncParameters  
#

SYNC_MODE="ASENewBackupSyncParameters" 

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
## Get API Version Info ...

apival=$( jqGet_APIVAL )
echo "Delphix Engine API Version: ${apival}"

#########################################################
## Get or Create Group 

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Group Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "Delphix Engine Group Reference: ${GROUP_REFERENCE}"

#########################################################
## Get Environment reference

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

ENV_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_ENV}"'") | .reference '`
echo "Source environment reference: ${ENV_REFERENCE}"

ENV_STAGE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${STAGE_ENV}"'") | .reference '`
echo "Staging environment reference: ${ENV_STAGE}"

#
# ASE Requires User Information ...
#
ENV_REF_USER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_ENV}"'") | .primaryUser '`
echo "Source environment reference user: ${ENV_REF_USER}"
ENV_STAGE_USER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${STAGE_ENV}"'") | .primaryUser '`
echo "Staging environment reference user: ${ENV_STAGE_USER}"

#########################################################
## Get Repository reference

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Repository Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

REP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_REFERENCE}"'" and .name=="'"${SOURCE_INSTANCE}"'") | .reference '`
echo "Source repository reference: ${REP_REFERENCE}"

REP_STAGE=`echo ${STATUS} | jq --raw-output '.result[] | select(.environment=="'"${ENV_STAGE}"'" and .name=="'"${STAGE_INSTANCE}"'") | .reference '`
echo "Staging repository reference: ${REP_STAGE}"

#########################################################
## Get sourceconfig

STATUS=`curl -s -X GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Source Config Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

SOURCE_CFG=`echo ${STATUS} | jq --raw-output '.result[] | select(.repository=="'"${REP_REFERENCE}"'" and .name=="'"${SOURCE_SID}"'") | .reference '`
echo "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Link Source Database ...

json="{
    \"type\": \"LinkParameters\",
    \"group\": \"${GROUP_REFERENCE}\",
    \"linkData\": {
        \"type\": \"ASELinkData\",
        \"config\": \"${SOURCE_CFG}\",
        \"dbCredentials\": {
            \"type\": \"PasswordCredential\",
            \"password\": \"${SOURCE_DB_PASS}\"
        },
        \"dbUser\": \"${SOURCE_DB_USER}\",
        \"loadBackupPath\": \"${BACKUPPATH}\",
        \"sourceHostUser\": \"${ENV_REF_USER}\",
        \"stagingHostUser\": \"${ENV_STAGE_USER}\",
        \"stagingRepository\": \"${REP_STAGE}\",
        \"syncParameters\": {
            \"type\": \"ASENewBackupSyncParameters\"
        }
    },
    \"name\": \"${DELPHIX_NAME}\"
}"

echo "Linking json=$json" | sed 's/"password": [^[:space:]]*/"password": "******" /g'

echo "Linking Source Database ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/link -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "Link Database: ${STATUS}"
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


#########################################################
#
# sync snapshot ...
#
# SQLSERVER link automatically submits a "sync" snapshot job, so no need to call it explicitly here ...
#
#echo "Running SnapSync ..."
#STATUS=`curl -s -X POST -k --data @- $BaseURL/database/${CONTAINER}/sync -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
#{
#    "type": "MSSqlSyncParameters"
#}
#EOF
#`

##echo ${STATUS}
## {"type":"OKResult","status":"OK","result":"","job":"JOB-49","action":"ACTION-232"}
#RESULTS=$( jqParse "${STATUS}" "status" )

#########################################################
#
# Get Job Number ...
#
#JOB=$( jqParse "${STATUS}" "job" )
#
# SQLSERVER link automatically submits a "sync" snapshot job, so increment previous JOB # by 1 and monitor ...
#
curr="JOB-511"
n=${JOB##*[!0-9]}; 
p=${JOB%%$n}
JOB=`echo "$p$((n+1))"`

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


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
# Program Name : provision_hana.sh
# Description  : Sample Script to provision a HANA vFiles
# Author       : Alan Bitterman
# Created      : 2017-09-29
# Version      : v1.1
#
#
#######################################################################
#
# Engine and API URL Parameters ...
# 
DMIP="10.0.1.10"
DMUSER="delphix_admin"
DMPASS="delphix"
COOKIE="~/cookies.txt"
COOKIE=`eval echo $COOKIE`
CONTENT_TYPE="Content-Type: application/json"
DELAYTIMERSEC=10
BaseURL="http://${DMIP}/resources/json/delphix"
DT=`date '+%Y%m%d%H%M%S'`

#######################################################################
#
# User Provided Parameters ...
# 
SOURCE_SID="HANALAB"    		# Source Object ...

DELPHIX_GRP="Targets"			# Delphix Group Object Name ...
VDB_NAME="hanavdb2"			# Target vFiles Name ... 

TARGET_ENV="Target"                     # Target Env ...
TARGET_INSTANCE="HANA 1.00.121.00 /usr/sap/HDB"  # Target Instance on Target Env ..
TARGET_USER="hdbadm"                    # Target User ...
##??##TARGET_PASS="delphix"                   

#
# Get Source Parameters ... 
#
SOURCE_PARAMETERS="{
   \"systemUserPassword\": \"delphix\",
   \"targetLicenceFilePath\": \"\",
   \"targetHost\": \"hanatarget\"
}
"

#######################################################################
## No changes below this point is required ...

#######################################################################
#
# Authenticaion ...
# 
json="{
   \"version\":{
      \"major\":1
     ,\"micro\":2
     ,\"minor\":8
     ,\"type\":\"APIVersion\"
   }
   ,\"type\":\"APISession\"
}
"
#echo "JSON: $json"

#
# Session ...
#
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

#echo "${STATUS}" | jq "."

json="{
 \"password\":\"${DMPASS}\"
,\"target\":\"DOMAIN\"
,\"username\":\"${DMUSER}\"
,\"type\":\"LoginRequest\"
}
"

#
# Login ...
#
STATUS=`curl -s -X POST -k --data @- ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

#echo "${STATUS}" | jq "."
echo "Login Successfull ..."

#######################################################################
#
# Get Group Reference ...
# 
STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."

GROUP_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "Group Reference: ${GROUP_REF}"

#######################################################################
#
# Get Database Container Reference ...
# 
STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."

CONTAINER_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${SOURCE_SID}"'") | .reference '`
echo "Container Reference: ${CONTAINER_REF}"

#######################################################################
#
# Get Environment Reference ...
#
STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."

ENV_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${TARGET_ENV}"'") | .reference '`
echo "Environment Reference: ${ENV_REF}"

#######################################################################
#
# Get Repository Reference ... 
#
STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."

REPOSITORY_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.environment=="'"${ENV_REF}"'" and .name=="'"${TARGET_INSTANCE}"'") | .reference '`
echo "Repository Reference: ${REPOSITORY_REF}"

#######################################################################
#
# Get User ...
#
STATUS=`curl -s -X GET -k ${BaseURL}/environment/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq "."

HOST_USER_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select (.environment=="'"${ENV_REF}"'" and .name=="'"${TARGET_USER}"'") | .reference '`

echo "Host User Reference: ${HOST_USER_REF}"

#######################################################################
#
# Provision HANA ...
# 
json="{
    \"type\": \"AppDataProvisionParameters\",
    \"container\": {
        \"type\": \"AppDataContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REF}\",
        \"sourcingPolicy\": {
            \"type\": \"SourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": false
        }
    },
    \"source\": {
        \"type\": \"AppDataVirtualSource\",
        \"name\": \"${VDB_NAME}\",
        \"additionalMountPoints\": [],
        \"allowAutoVDBRestartOnHostReboot\": false,
        \"operations\": {
            \"type\": \"VirtualSourceOperations\",
            \"configureClone\": [],
            \"postRefresh\": [],
            \"postRollback\": [],
            \"postSnapshot\": [],
            \"postStart\": [],
            \"postStop\": [],
            \"preRefresh\": [],
            \"preRollback\": [],
            \"preSnapshot\": [],
            \"preStart\": [],
            \"preStop\": []
        },
        \"parameters\": ${SOURCE_PARAMETERS}
    },
    \"sourceConfig\": {
        \"type\": \"AppDataDirectSourceConfig\",
        \"name\": \"${VDB_NAME}\",
        \"environmentUser\": \"${HOST_USER_REF}\",
        \"linkingEnabled\": false,
        \"repository\": \"${REPOSITORY_REF}\",
        \"parameters\": {},
        \"path\": \"/mnt/provision/${VDB_NAME}\"
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REF}\"
    }
}
"

echo "${json}" | jq "."

STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

echo "Provision Job Request Status: "
echo "${STATUS}" | jq "."

echo " " 
echo "Done .."
echo " "
exit 0;


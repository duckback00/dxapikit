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
# Program Name : user_timeout_jq.sh
# Description  : Delphix API to update user timeout
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
# Usage: ./user_timeout_jq.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Required for user timeout ...
#
DE_USER="delphix_admin"          # Delphix Engine User
DE_TIMEOUT=150                   # Timeout integer in minutes

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
## Authentication ...

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
## Get User Reference ... 

STATUS=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference for name ${SOURCE_GRP} ...
#
USER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DE_USER}"'") | .reference '`
echo "user reference: ${USER_REFERENCE}"

#########################################################
## Update User Session Timeout ...

echo "Update ${DE_USER} session timeout value to ${DE_TIMEOUT} minutes ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/user/${USER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "User",
    "sessionTimeout": ${DE_TIMEOUT}
}
EOF
`

echo "Returned JSON: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )
echo "Results: ${RESULTS}"

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0;


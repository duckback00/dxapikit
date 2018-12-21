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
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Program Name : create_support_bundle.sh
# Description  : Delphix API for generate a local support bundle
# Author       : Serge DeLasablonniere
# Created      : 2018-10-01
# Version      : v1.0
#
# REMOVED all jq references 
#
# Requirements :
#  1.) curl command line library
#  2.) Populate Delphix Engine Connection Information
#
# Usage:
# ./create_support_bundle.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

#. ./delphix_engine.conf
#
# Delphix Engine Configuration Parameters ...
# 

# HTTP ...
DMIP="172.16.160.195"
BaseURL="http://${DMIP}/resources/json/delphix"

# HTTPS ...
#DMIP="34.229.130.64:443"
#BaseURL="https://${DMIP}/resources/json/delphix"

DMUSER=delphix_admin
DMPASS=delphix
COOKIE="~/cookies.txt"            # or use /tmp/cookies.txt 
COOKIE=`eval echo $COOKIE`
CONTENT_TYPE="Content-Type: application/json"
DELAYTIMESEC=10
DT=`date '+%Y%m%d%H%M%S'`

#
# Dump File Path ...
#
BUNDLE_PATH="/tmp"  

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

STATUS=`curl -s -X POST -k --data @- $BaseURL/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 9,
        "micro": 0
    }
}
EOF
`

#echo "Session: ${STATUS}"

STATUS=`curl -s -X POST -k --data @- $BaseURL/login -b "${COOKIE}" -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LoginRequest",
    "username": "${DMUSER}",
    "password": "${DMPASS}"
}
EOF
`

#echo "Login: ${STATUS}"

echo "Session and Login Successful ..."

#########################################################
## Generate Support Bundle ...

echo " "
echo "API Call to Generate a Support Bundle ..."
echo "Please wait, this can take several minutes to complete"

#
# Local File ...
#
STATUS=`curl -s -X POST -k ${BaseURL}/service/support/bundle/generate -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "STATUS> ${STATUS}"

#
# or Upload the bundle to Delphix (Requires Internet Access) ...
#
#STATUS=`curl -s -X POST -k ${BaseURL}/service/support/bundle/upload -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "STATUS> ${STATUS}" 

TOKEN=`echo "${STATUS}" | awk -F '"result":' '{print $2}' | cut -d, -f1 | sed 's/"//g'`
#dcddea04-7950-4c67-8d2a-a4bac5fdcc90
echo "Token for download is ${TOKEN}"

TOKEN_FILE="${BUNDLE_PATH}/${TOKEN}.tar.gz"
##echo "Bundle will be saved in ${TOKEN_FILE}"

echo " "
echo "API Call to Download the Bundle to a local file ..."
curl -s -X GET -k ${BaseURL}/data/download?token=${TOKEN} -b "${COOKIE}" -H "${CONTENT_TYPE}" > ${TOKEN_FILE}

echo "Delphix Support Bundle saved in ${TOKEN_FILE}"

echo " "
echo "Done ..."
exit 0

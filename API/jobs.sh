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
# Program Name : jobs.sh
# Description  : Delphix API to get Jobs 
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
# Usage: ./jobs.sh
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

#
# Session ...
#
echo "Session API "
curl -s -X POST -k --data @- ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 7,
        "micro": 0
    }
}
EOF



#
# Login ...
#
echo " "
echo "Login API "
curl -s -X POST -k --data @- ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
  "type": "LoginRequest",
  "username": "${DMUSER}",
  "password": "${DMPASS}"
}
EOF



TDT="2017-04-01T01:43:24.246Z"
TDT=$(sed -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\&/%26/g' -e 's/'\''/%28/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/{/%7B/g' -e 's/}/%7D/g' -e 's/:/%3A/g' -e 's/\//%2F/g'<<<$TDT);

#echo ""
#echo $TDT

echo " "
echo "Job API "
#STATUS=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT}&pageSize=10 -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job?fromDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
STATUS=`curl -s -X GET -k ${BaseURL}/job?pageSize=1000 -b "${COOKIE}" -H "${CONTENT_TYPE}"`


#echo "STATUS> ${STATUS}" 

#curl -s -X GET -k ${BaseURL}/job?toDate=2017-04-01T01%3A43%3A24.246Z -b "${COOKIE}" -H "${CONTENT_TYPE}"
#TMP=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "TMP> ${TMP}"


# 
# Show Pretty (Human Readable) Output ...
#
echo ${STATUS} | jq "."


#################################################################################
# 
# Some jq parsing examples ...
#

#ACTION="DB_LINK"
#echo "${ACTION}"
#echo "${STATUS}" | jq --raw-output '.result[] | select(.actionType=="'"${ACTION}"'") '

#ACTION="DB_PROVISION"
#echo "${ACTION}"
#echo "${STATUS}" | jq --raw-output '.result[] | select(.actionType=="'"${ACTION}"'") '

# 
# The End is Hear ...
#
echo " "
echo "Done "
exit 0;


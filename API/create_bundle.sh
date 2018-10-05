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
# Program Name : create_bundle.sh
# Description  : Delphix API for generate a local support bundle
# Author       : Serge DeLasablonniere
# Created      : 2018-10-01
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Usage:
# ./create_bundle.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#
# See TOKEN_FILE variable value below for dump file location
#

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Generate Support Bundle ...

echo " "
echo "API Call to Generate a Support Bundle "
echo "Please wait ... this can take several minutes to complete"

STATUS=`curl -s -X POST -k ${BaseURL}/service/support/bundle/generate -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X POST -k ${BaseURL}/service/support/bundle/upload -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#echo "STATUS> ${STATUS}" 

# 
# Show Pretty (Human Readable) Output ...
#
#echo ${STATUS} | jq "."

TOKEN=`echo ${STATUS} | jq --raw-output ".result"`

TOKEN_FILE=/tmp/${TOKEN}.tar.gz

echo "Token for download is ${TOKEN}"
echo "Bundle will be saved in ${TOKEN_FILE}"
echo " "
echo "API Call to export Export the Bundle to a file"
curl -s -X GET -k ${BaseURL}/data/download?token=${TOKEN} -b "${COOKIE}" -H "${CONTENT_TYPE}" > ${TOKEN_FILE}

echo " "
echo "Done ..."
exit 0;

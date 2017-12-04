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
# Program Name : jetstream_objects_json.sh 
# Description  : Delphix API for Jetstream Objects
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: 
# . ./jetstream_objects_json.sh
#
# The JSON environment variable will contain the API JSON data output from the APIs called within this script
# Examples:
#  echo $JSON
#  echo $JSON | jq "."
#  echo $JSON | jq ".jetstream[] | select (.template)"
#  echo $JSON | jq ".jetstream[] | select (.datatsource)"
#  echo $JSON | jq ".jetstream[] | select (.container)"
#  echo $JSON | jq ".jetstream[] | select (.branch)"
#  echo $JSON | jq ".jetstream[] | select (.bookmark)"
#  echo $JSON | jq ".jetstream[] | select (.operation)"
#
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Session and Login ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ] 
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#
# Build JSON String with Jetstream Objects ...
#

JSON="{ \"jetstream\": [ ";

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON { \"template\": ${STATUS} }"

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON , { \"datasource\": ${STATUS} }"

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON , { \"container\": ${STATUS} }"

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON , { \"branch\": ${STATUS} }"

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON , { \"bookmark\": ${STATUS} }"

STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/operation -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
JSON="$JSON , { \"operation\": ${STATUS} }"

#
# The end of concatenating JSON strings ...
#
JSON="$JSON ] }"

#echo $JSON

export JSON

echo "# Usage: . ./jetstream_objects_json.sh"
echo "# The JSON environment variable will contain the API JSON data output from the APIs called within this script"
echo "# Examples: "
echo "#  echo \$JSON"
echo "#  echo \$JSON | jq \".\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.template)\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.datasource)\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.container)\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.branch)\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.bookmark)\""
echo "#  echo \$JSON | jq \".jetstream[] | select (.operation)\""

echo " "
echo "Done ..."
echo " "
### exit 0

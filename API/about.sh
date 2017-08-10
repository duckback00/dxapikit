#!/bin/sh
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
# Program Name : about.sh
# Description  : Delphix API about call 
# Author       : Alan Bitterman
# Created      : 2017-08-12
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Usage: ./about.sh
#
#########################################################
#                   DELPHIX CORP                        #
#########################################################

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

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



echo " "
echo "About API "
STATUS=`curl -s -X GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}"`

# 
# Show Pretty (Human Readable) Output ...
#
echo ${STATUS} | jq "."


#################################################################################
# 
# Some jq parsing examples ...
#

#
# Get Delphix Engine Build Version ...
# 
major=`echo ${STATUS} | jq --raw-output ".result.buildVersion.major"`
minor=`echo ${STATUS} | jq --raw-output ".result.buildVersion.minor"`
micro=`echo ${STATUS} | jq --raw-output ".result.buildVersion.micro"`

let buildval=${major}${minor}${micro}
echo "Delphix Engine Build Version: ${major}${minor}${micro}"

#set -x
if [ "${buildval}" == "" ] 
then
  echo "Error: Delphix Engine Build Version Value Unknown ${buildval} ..."
else
   if [ $buildval -lt 510 ]
   then
      echo "before Illium"
   else
      echo "Illium or later"
   fi
fi

#
# Get Delphix Engine API Version ...
#
major=`echo ${STATUS} | jq --raw-output ".result.apiVersion.major"`
minor=`echo ${STATUS} | jq --raw-output ".result.apiVersion.minor"`
micro=`echo ${STATUS} | jq --raw-output ".result.apiVersion.micro"`

let apival=${major}${minor}${micro}
echo "Delphix Engine API Version: ${major}${minor}${micro}"

if [ "$apival" == "" ]
then
  echo "Error: Delphix Engine API Version Value Unknown $apival ..."
else
   if [ $apival -lt 180 ]
   then
      echo "before Illium"
   else
      echo "Illium or later"
   fi
fi


#
# Get Delphix Engine Enabled Features ...
# 
features=`echo ${STATUS} | jq --raw-output ".result.enabledFeatures"`
echo "Features: ${features}" 

#
# Remove line feeds and square brackets ...
#
features=`echo ${features} | tr '\n' ' ' | sed 's/.*\[//;s/\].*//;' | tr -d '"' `

#
# Parse String into a shell Array ...
#
IFS=,
ary=($features)
for key in "${!ary[@]}"; 
do 
   #echo "$key |${ary[$key]}|";
   #
   # Remove leading and Trailing Spaces ...
   #
   tmp=`echo ${ary[$key]} | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//'`
   echo "$key |${tmp}|"; 
done
IFS=


# 
# The End is Hear ...
#
echo " "
echo "Done "
exit 0;


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
# Copyright (c) 2019 by Delphix. All rights reserved.
#
# Program Name : performanceHistory.sh
# Description  : Delphix API Database performanceHistory call 
# Author       : Alan Bitterman
# Created      : 2019-06-26
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Usage:
# ./performanceHistory.sh
# ./performanceHistory.sh [vdb_name] [fromDate] [toDate] [samplingInterval]
# 
# samplingInterval (secs) where 3600=1hr 86400=24hrs
# 
# Examples:
# ./performanceHistory.sh Vdelphix_demo 6/22 6/28 86400
# ./performanceHistory.sh Vdelphix_demo 2019/06/22 2019/06/28 86400
# ./performanceHistory.sh Vdelphix_demo 2019-06-22 2019-06-28 86400
# ./performanceHistory.sh Vdelphix_demo 2019-06-22T00:00:00.000Z 2019-06-28T00:00:00.000Z 84000
#
#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

let TIMEZONE=-4         # Timezone -4 ET, -5 CT, -6 MT, -7 PT

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Authentication ...

#echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

##echo "Session and Login Successful ..."

#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

SOURCE_SID="$1"
if [[ "${SOURCE_SID}" == "" ]]
then

   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
   echo "---------------------------------"
   echo "VDB Names: [copy-n-paste]"
   echo "${VDB_NAMES}"
   echo " "

   echo "Please Enter dSource or VDB Name (case sensitive): "
   read SOURCE_SID
   if [[ "${SOURCE_SID}" == "" ]]
   then
      echo "No dSource or VDB Name Provided, Exiting ..."
      exit 1
   fi
fi

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'" and .namespace==null) | .reference '`
##echo "database container reference: ${CONTAINER_REFERENCE}"
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   echo "Error: No container found for ${SOURCE_SID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1;
fi
CONTAINER_TYPE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'" and .namespace==null) | .type '`
##echo "database container type: ${CONTAINER_TYPE}"


#########################################################
## GNU Date (difference between Mac and Linux platforms)

which gdate 1> /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
   GDT=gdate
else
   GDT=date
fi
#echo "Date Command: ${GDT}"

#
# Timestamp ...
#
TZ=$2
if [[ "${TZ}" == "" ]]
then
   echo " "
   echo "Valid Example Formats:  6/22  2019-06-22"
   echo "Enter \"fromDate\" Timestamp: "
   read TZ
   if [[ "${TZ}" == "" ]]
   then
      echo "No Timestamp provided, exiting ... ${TZ} "
      exit 1
   fi
fi

#########################################################
## Check for Valid Date input ...

#echo "${TZ}"
${GDT} --date="${TZ}" "+%Y/%m/%d %H:%M:%S"  1> /dev/null 2> /dev/null
if [ $? -ne 0 ]
then
   echo "invalid date, exiting ..."
   exit 1
fi

## Convert User Time to Generic Valid Timestamp Format then into Delphix Format ...
DT=`${GDT} --date="${TZ}" "+%Y/%m/%d %H:%M:%S"`
let TMP=${TIMEZONE}*2
fromDate=`${GDT} --date="${DT} ${TMP}" "+%Y-%m-%dT00:00:00.000Z"`

#
# Timestamp ...
#
TZ=$3
if [[ "${TZ}" == "" ]]
then
   echo " "
   echo "Valid Example Formats:  6/28  2019-06-28"
   echo "Enter \"toDate\" Timestamp: "
   read TZ
   if [[ "${TZ}" == "" ]]
   then
      echo "No Timestamp provided, exiting ... ${TZ} "
      exit 1
   fi
fi

#########################################################
## Check for Valid Date input ...

#echo "${TZ}"
${GDT} --date="${TZ}" "+%Y/%m/%d %H:%M:%S"  1> /dev/null 2> /dev/null
if [ $? -ne 0 ]
then
   echo "invalid date, exiting ..."
   exit 1
fi

## Convert User Time to Generic Valid Timestamp Format then into Delphix Format ...
DT=`${GDT} --date="${TZ}" "+%Y/%m/%d %H:%M:%S"`
toDate=`${GDT} --date="${DT} ${TMP}" "+%Y-%m-%dT00:00:00.000Z"`


samplingInterval=$4
if [[ "${samplingInterval}" == "" ]]
then
   echo " "
   echo "Enter samplingInterval (secs) 3600=1hr 86400=24hrs: "
   read samplingInterval
   if [[ "${samplingInterval}" == "" ]]
   then
      echo "No samplingInterval provided, exiting ... ${samplingInterval} "
      exit 1
   fi
fi

## DEBUG ## echo " $fromDate ... $toDate ... $samplingInterval "

#########################################################
## API Call ...

#STATUS=`curl -s -X GET -k ${BaseURL}/database/performanceHistory?fromDate=2019-06-25T00:00:00.000Z'&'toDate=2019-06-27T00:00:00.000Z'&'samplingInterval=3600 -b "${COOKIE}" -H "${CONTENT_TYPE}"`

##echo "${BaseURL}/database/performanceHistory?fromDate=${fromDate}'&'toDate=${toDate}'&'samplingInterval=${samplingInterval}"
STATUS=`curl -s -X GET -k ${BaseURL}/database/performanceHistory?fromDate=${fromDate}'&'toDate=${toDate}'&'samplingInterval=${samplingInterval} -b "${COOKIE}" -H "${CONTENT_TYPE}"`

##echo ${STATUS} | jq -r "."

DATA=`echo ${STATUS} | jq -r ".result[] | select (.container==\"${CONTAINER_REFERENCE}\") "`
#echo "${DATA}" | jq -r '.utilization[] | .timestamp, .averageThroughput'
echo "timestamp,averageThroughput"
echo "${DATA}" | jq -r '.utilization[] | "\(.timestamp),\(.averageThroughput)"'

#########################################################
## The End is Here ...

exit 0;

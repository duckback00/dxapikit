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
# Program Name : timestamp.sh
# Description  : Delphix API to find Timestamps within Timeflows 
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
# Usage: ./timestamp.sh
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

function is_between() {
   #set -x
   d1=$1                  # start
   d2=$2                  # end
   d3=$3                  # check

   l1=$(echo $d1 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
   l2=$(echo $d2 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
   l3=$(echo $d3 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')

   read -r y M d h m s ms <<<${l1}
   if [[ ${#M} -lt 2 ]]; then
      M="0"${M}
   fi
   d=${d#0}
   h=${h#0}
   m=${m#0}
   s=${s#0}
   s1=${y}${M}$((($d*1440*60*1000)+(h*60*60*1000)+(m*60*1000)+(s*1000)+ms))

   read -r y M d h m s ms <<<${l2}
   if [[ ${#M} -lt 2 ]]; then
      M="0"${M}
   fi
   d=${d#0}
   h=${h#0}
   m=${m#0}
   s=${s#0}
   s2=${y}${M}$((($d*1440*60*1000)+(h*60*60*1000)+(m*60*1000)+(s*1000)+ms))

   read -r y M d h m s ms <<<${l3}
   if [[ ${#M} -lt 2 ]]; then
      M="0"${M}
   fi
   d=${d#0}
   h=${h#0}
   m=${m#0}
   s=${s#0}
   s3=${y}${M}$((($d*1440*60*1000)+(h*60*60*1000)+(m*60*1000)+(s*1000)+ms))

   let s1=${s1}
   let s2=${s2}
   let s3=${s3}
   #echo "DEBUG: ${s1} ... ${s2} ... ${s3}" 
   if [[ s3 -le s2 ]] && [[ s3 -ge s1 ]]
   then
      echo "true"
   else 
      echo "false"
   fi
}

#results=$(is_between "2016-10-19T02:24:21.000Z" "2016-10-20T02:24:21.000Z" "2016-10-19T02:24:21.002Z")

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

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

#########################################################
## Get database list ...

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "database: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#########################################################
## Command Line Arguments ...

SOURCE_SID=$1
if [[ "${SOURCE_SID}" == "" ]]
then
   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
   echo "VDB Names:"
   echo "${VDB_NAMES}"
   echo " "
   echo "Please Enter dSource or VDB Name: "
   read SOURCE_SID
   if [[ "${SOURCE_SID}" == "" ]]
   then
      echo "No dSource of VDB Name Provided, Exiting ..."
      exit 1
   fi
fi 

TZ=$2
if [[ "${TZ}" == "" ]]
then
   echo " "
   echo "Timestamp Format \"[yyyy]-[MM]-[dd]T[HH]:[mm]:[ss].[SSS]Z\""
   echo "Example: 2016-10-19T02:24:21.000Z"
   echo "Enter Search Timestamp (exclude quotes): "
   read TZ
   if [[ "${TZ}" == "" ]]
   then
      echo "No Timestamp provided, exiting ... ${TZ} "
      exit 1
   fi
fi

#########################################################
## Get database container ...

echo "Source: ${SOURCE_SID}"
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## List timeflows for the container reference

##echo "Timeflows API "
STATUS=`curl -s -X GET -k ${BaseURL}/timeflow -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#########################################################
## Select the timeflow ...

FLOW_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .name '`
##echo "timeflow names:"
##echo "${FLOW_NAMES}"
##echo " "

#
# Individual Timeflow ...
#
#echo "Select timeflow Name (copy-n-paste from above list): "
#read FLOW_NAME
#if [ "${FLOW_NAME}" == "" ]
#then
#   echo "No Flow Name provided, exiting ... ${FLOW_NAME} "
#   exit 1;
#fi

#
# Loop through each Timeflow ...
# 
while read -r FLOW_NAME 
do
   echo "-------------------------------------------------------"
   echo "Processing Timeflow: $FLOW_NAME"

   # Get timeflow reference ...
   FLOW_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME}"'") | .reference '`
   ##echo "timeflow reference: ${FLOW_REF}"

   # timeflowRanges for this timeflow ...
   #echo "TimeflowRanges for this timeflow ... "
   TSTATUS=`curl -s -X POST -k --data @- ${BaseURL}/timeflow/${FLOW_REF}/timeflowRanges -b "${COOKIE}" -H "${CONTENT_TYPE}" <<-EOF
{
    "type": "TimeflowRangeParameters"
}
EOF
`
   #echo ${TSTATUS} | jq --raw-output '.'

   #
   # Process each row within the TimeflowRange ...
   #
   ROWS=`echo ${TSTATUS} | jq --raw-output '.total'`
   for (( i=0; i < $ROWS; ++i ))
   do
      PV=""
      ST=""
      ET=""
      #echo "output: $i"
      #echo "Is Provisionable and startPoint and endPoint values ..."
      #echo "${TSTATUS}" | jq --raw-output ".result[$i].provisionable"
      #echo "${TSTATUS}" | jq --raw-output ".result[$i].startPoint.timestamp"
      #echo "${TSTATUS}" | jq --raw-output ".result[$i].endPoint.timestamp"

      PV=`echo "${TSTATUS}" | jq --raw-output ".result[$i].provisionable"`
      ST=`echo "${TSTATUS}" | jq --raw-output ".result[$i].startPoint.timestamp"`
      ET=`echo "${TSTATUS}" | jq --raw-output ".result[$i].endPoint.timestamp"`

      echo "Is ${TZ} is between ${ST} and ${ET} ?"
      results=$(is_between "${ST}" "${ET}" "${TZ}")
      #echo "is_between results: ${results}" 
      if [[ "${results}" == "true" ]]
      then
         if [[ "${PV}" == "true" ]] 
         then
            echo "Yes, timestamp found in Timeflow Reference: ${FLOW_REF} and IS provisionable"
         else
            echo "Yes, timestamp found in Timeflow Reference: ${FLOW_REF} but IS NOT provisionable"
         fi 
      else 
         echo "No"
      fi
   done

done <<< "${FLOW_NAMES}"

echo "Done ..."
exit 0


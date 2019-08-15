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
# Program Name : get_time_object.sh
# Description  : Delphix API timeflows examples
# Author       : Alan Bitterman
# Created      : 2019-05-14
# Version      : v1.0.3 2019-05-29
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Include ./jqJSON_subroutines.sh
#  3.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Interactive Usage: ./get_time_object.sh
#
#                                                                                           Returned Reference snapshot param only
# Non-Interactive Usage: ./get_time_object.sh [rewind|refresh] [database_name] [timestamp] [snapshot|timeflow] [nearest|before|after]   
#
# Examples:
# ./get_time_object.sh refresh VBITT "10:30am" timeflow
# ./get_time_object.sh refresh VBITT "10:30am" snapshot nearest 
#
#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#
# use timezone differenace -4 + -10 = -14 for 10hrs
#
let TIMEZONE=-4         # Timezone -4 ET, -5 CT, -6 MT, -7 PT

# ========================================================
# Important NOTE:
#   Need to adjust the PAGESIZE and the TODATE value to 
#   ensure available snapshots for user provided timestamp
#
# So a TODATE of -6 with a timezone of -4 and PAGESIZE=100 
# will provide the last 100 snapshots up to 2 hours beyond 
# the requested timestamp. 
# ========================================================

let PAGESIZE=50
TODATE="-6"             # "tomorrow"    # "next Week"

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

. ./jqJSON_subroutines.sh

# 
# Is Timestamp between 2 other Timestamps function ...
#
# RESULTS=$(is_between "2016-10-19T02:24:21.000Z" "2016-10-20T02:24:21.000Z" "2016-10-19T02:24:21.002Z")
#
function is_between() {
   ###set -x
   d1=$1                  # start
   d2=$2                  # end
   d3=$3                  # check

   l1=$(echo $d1 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
   l2=$(echo $d2 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
   l3=$(echo $d3 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')

   s1=`echo "${l1}" | sed "s/ //g"`
   s2=`echo "${l2}" | sed "s/ //g"`
   s3=`echo "${l3}" | sed "s/ //g"`

   let s1=${s1}
   let s2=${s2}
   let s3=${s3}
   #echo "DEBUG: Is ${s3} between ${s1} ... ${s2}" 
   if [[ s3 -le s2 ]] && [[ s3 -ge s1 ]]
   then
      echo "true"
   else 
      echo "false"
   fi
}

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

#########################################################
## Session and Login ...

#echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [[ "${RESULTS}" != "OK" ]]
then
   echo "Error: Exiting ..."
   exit 1;
fi

#echo "Session and Login Successful ..."

#########################################################
## Get database list ...

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq -r "."

#########################################################
## Command Line Arguments ...

#
# rewind | refresh
# 
ACTION=$1
if [[ "${ACTION}" == "" ]]
then
   echo " "
   echo "Enter object action [rewind|refresh]:"
   read ACTION
   if [[ "${ACTION}" == "" ]]
   then
      echo "No action ${ACTION} Provided, Exiting ..."
      exit 1
   fi
fi

#
# Database Name ...
#
SOURCE_SID=$2
if [[ "${SOURCE_SID}" == "" ]]
then
   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select (.namespace==null) | .name '`
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

#
# Timestamp ...
#
TZ=$3
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

#
# Action Type Timepoint ...
# [snapshot|timeflow]
#
TYPE_TIME=$4
if [[ "${TYPE_TIME}" == "" ]]
then
   echo " "
   echo "Return Object [ snapshot | timeflow ]: "
   read TYPE_TIME
   if [[ "${TYPE_TIME}" == "" ]]
   then
      echo "No Return Object Type provided, exiting ... ${TYPE_TIME} "
      exit 1
   fi
fi

#
# Snapshot selection ...
# [nearest|before|after]
#
if [[ "${TYPE_TIME}" == "snapshot" ]]
then
   TIME_POINT=$5
   if [[ "${TIME_POINT}" == "" ]]
   then
      echo " "
      echo "Timepoint [ nearest | before | after ]: "
      read TIME_POINT
      if [[ "${TIME_POINT}" == "" ]]
      then
         echo "No Timepoint Argument provided, exiting ... ${TIME_POINT} "
         exit 1
     fi
   fi
else
   TIME_POINT=""
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

#
# Convert User Time to Generic Valid Timestamp Format ...
#
DT=`${GDT} --date="${TZ}" "+%Y/%m/%d %H:%M:%S"`

#
# Engine UTC time in Generic Valid Timestamp Format ...
# User Time already has Timezone, so need to subtract Timezone for UTC
#
let TMP=${TIMEZONE}*2
#echo "${GDT} --date=\"${DT} ${TMP}\" \"+%Y/%m/%d %H:%M:%S\""
UTZ=`${GDT} --date="${DT} ${TMP}" "+%Y/%m/%d %H:%M:%S"`

#
# Get toDate timestamp in Delphix Timestamp Format for snapshots API query ...
#
#echo "${GDT} --date=\"${UTZ} ${TODATE}\" \"+%Y-%m-%dT%H:%M:%S.000Z\""
TZA=`${GDT} --date="${UTZ} ${TODATE}" "+%Y-%m-%dT%H:%M:%S.000Z"`

#
# Convert Dates to Delphix Timestamp Format ...
#
TZ=`${GDT} --date="${DT} ${TIMEZONE}" "+%Y-%m-%dT%H:%M:%S.000Z"`
UTZ=`${GDT} --date="${UTZ}" "+%Y-%m-%dT%H:%M:%S.000Z"`
#echo "User: ${TZ} ... ${TMP} Engine: ${UTZ} ...toDate: ${TZA}"

#
# Escape toDate ${TZA} value semi-colons ...
#
TZA=`echo "${TZA}" | sed s/:/%3A/g`
#echo "${TZA}"

#########################################################
## Get database container ...

#echo "Source: ${SOURCE_SID}"
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'" and .namespace==null) | .reference '`
PARENT_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'" and .namespace==null) | .provisionContainer'`

#echo "container reference: ${CONTAINER_REFERENCE}"
#echo "parent reference: ${PARENT_REFERENCE}"

#########################################################
## List timeflows for the container reference ...

if [[ "${ACTION}" == "refresh" ]]
then
   STATUS=`curl -s -X GET -k ${BaseURL}/timeflow?database=${PARENT_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
elif [[ "${ACTION}" == "rewind" ]]
then
   STATUS=`curl -s -X GET -k ${BaseURL}/timeflow?database=${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
else
   echo "Error: Invalid action ${ACTION}, please retry with [rewind|refresh] exiting ..."
   exit 1;
fi
#echo "${STATUS}" | jq -r "."

#
# Get Row Total to see if dSource, total = 1 or VDB ..
#
ROWS=`echo ${STATUS} | jq --raw-output '.total'`
##echo "$ROWS ... ${TYPE_TIME}"
if [[ ${ROWS} -eq 1 ]] && [[ "${TYPE_TIME}" == "snapshot" ]]
then

   FLOW_NAME_FOUND=`echo "${STATUS}" | jq --raw-output '.result[] | select (.namespace==null) | .name'`
   FLOW_FOUND=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME_FOUND}"'" and .namespace==null) | .reference '`
   FLOW_PROVISIONABLE="true"
   ###echo "FLOW_NAME: ${FLOW_NAME_FOUND} ... FLOW_REF: ${FLOW_FOUND}"

elif [[ ${ROWS} -gt 0 ]] 
then

   FLOW_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | select (.namespace==null) | .name'`
   ###echo "Flow Names: ${FLOW_NAMES}"
   FLOW_FOUND="null"
   FLOW_NAME_FOUND="null"
   FLOW_PROVISIONABLE="false"
   while read -r FLOW_NAME 
   do
      #echo "-------------------------------------------------------"
      #echo "Processing Timeflow: $FLOW_NAME"

      # Get timeflow reference ...
      FLOW_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${FLOW_NAME}"'" and .namespace==null) | .reference '`
      #echo "timeflow reference: ${FLOW_REF}"

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
      TROWS=`echo ${TSTATUS} | jq --raw-output '.total'`
      if [[ ${TROWS} -ge 1 ]]
      then
         let i=0
         for (( i=0; i < ${TROWS}; ++i ))
         do

            # echo "${i} of ${TROWS}" ; date '+%Y%m%d%H%M%S'
            PV=""
            ST=""
            ET=""
            #echo "output: $i"
            PV=`echo "${TSTATUS}" | jq --raw-output ".result[$i].provisionable"`
            ST=`echo "${TSTATUS}" | jq --raw-output ".result[$i].startPoint.timestamp"`
            ET=`echo "${TSTATUS}" | jq --raw-output ".result[$i].endPoint.timestamp"`
      
            #echo "Is ${TZ} which is ${UTZ} UTC between ${ST} and ${ET} in ${FLOW_NAME}?"
            RESULTS=$(is_between "${ST}" "${ET}" "${UTZ}")
            #echo "is_between results: ${RESULTS}" 
            if [[ "${RESULTS}" == "true" ]]
            then
               FLOW_NAME_FOUND="${FLOW_NAME}"
               FLOW_FOUND="${FLOW_REF}"
               if [[ "${PV}" == "true" ]] 
               then
                  FLOW_PROVISIONABLE="true"
                  #echo "Yes, timestamp found in Timeflow Reference: ${FLOW_REF} and IS provisionable"
               else
                  FLOW_PROVISIONABLE="false"
                  #echo "Yes, timestamp found in Timeflow Reference: ${FLOW_REF} but IS NOT provisionable"
               fi 
            #else 
               #echo "No"
            fi
         done 
      fi				# end if ${TROWS}
   done <<< "${FLOW_NAMES}"
fi 			# end if ${ROWS} 

# 
# Return Timeflow ...
#
if [[ "${TYPE_TIME}" == "timeflow" ]]
then
   #echo "Timeflow Object Returned ..." 
   echo "{
  \"action\": \"${ACTION}\"
, \"database_name\": \"${SOURCE_SID}\"
, \"container_reference\": \"${CONTAINER_REFERENCE}\"
, \"provisionContainer\": \"${PARENT_REFERENCE}\"
, \"user_time\": \"${TZ}\"
, \"engine_time\": \"${UTZ}\"
, \"timeflow_name\": \"${FLOW_NAME_FOUND}\"
, \"timeflow_reference\": \"${FLOW_FOUND}\"
, \"timeflow_provisionable\": ${FLOW_PROVISIONABLE} 
}"
   exit 0
fi

if [[ "${TYPE_TIME}" != "snapshot" ]]
then
   echo "Invalid return object type, ${TYPE_TIME}, must be snapshot or timeflow, exiting ..."
   exit 1
fi

#########################################################
## Get snapshots ...

##echo "Finding ${UTZ} within Snapshots ..."

if [[ "${ACTION}" == "refresh" ]]
then

   # 
   # Get Parent Source Snapshots ...
   #
   ## echo "${ACTION} TEST: curl -s -X GET -k ${BaseURL}/snapshot?database=${PARENT_REFERENCE}'&'pageOffset=0'&'pageSize=${PAGESIZE}'&'toDate=${TZA} -b \"${COOKIE}\" -H \"${CONTENT_TYPE}\""
   ##curl -s -X GET -k ${BaseURL}/snapshot?database=${PARENT_REFERENCE}'&'pageOffset=0'&'pageSize=${PAGESIZE}'&'toDate=${TZA} -b "${COOKIE}" -H "${CONTENT_TYPE}" | jq ".result[].name"
   STATUS=`curl -s -X GET -k ${BaseURL}/snapshot?database=${PARENT_REFERENCE}'&'pageOffset=0'&'pageSize=${PAGESIZE}'&'toDate=${TZA} -b "${COOKIE}" -H "${CONTENT_TYPE}"`

elif [[ "${ACTION}" == "rewind" ]] 
then

   #
   # Get VDB Source Snapshots ...
   #
   ##echo "${ACTION} TEST: curl -s -X GET -k ${BaseURL}/snapshot?database=${CONTAINER_REFERENCE}'&'pageOffset=0'&'pageSize=${PAGESIZE}'&'toDate=${TZA} -b \"${COOKIE}\" -H \"${CONTENT_TYPE}\""
   STATUS=`curl -s -X GET -k ${BaseURL}/snapshot?database=${CONTAINER_REFERENCE}'&'pageOffset=0'&'pageSize=${PAGESIZE}'&'toDate=${TZA} -b "${COOKIE}" -H "${CONTENT_TYPE}"`

fi

#
# Sort Snapshots Names to allow for before/after computation ...
#
###echo "${STATUS}" | jq -r ".result[].name" | sort
SNAP_NAMES=`echo "${STATUS}" | jq -r ".result[].name" | sort`

#
# Convert User Timestamp in Engine Timezone to timestamp number ..
#
d3=${UTZ} 
l3=$(echo $d3 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
s3=`echo "${l3}" | sed "s/ //g"`
let s3=${s3}

# 
# Set Variables used within loop ...
#
SNAP_BEFORE=""
SNAP_AFTER=""
SNAP_NEAREST=""
let smin=s3
let smax=s3
let sdelta=s3
let i=0

#
# Loop through each Snapshot ...
#
while read -r snap_name
do
if [[ "${snap_name}" != "" ]] 
then
   let i=i+1
   d1=`echo "${STATUS}" | jq -r ".result[] | select (.name==\"${snap_name}\") | .creationTime"`
   ### DEBUG ##  echo "${i} Snapshot Name: ${snap_name}  Snapshot ${d1}"

   # 
   # Convert Snapshot Name to timestamp number ...
   #
   ##set -x
   l1=$(echo $d1 | tr '.:' ' ' | tr 'T' ' ' | tr 'Z' ' ' | tr '.-' ' ')
   s1=`echo "${l1}" | sed "s/ //g"`
   let s1=${s1}
   ## DEBUG ## echo "DEBUG: ${d1} ...${s1} ... ${s3} "

   # 
   # Before Snapshot Logic ...
   #
   if [[ s1 -le s3 ]] 
   then 
      let s4=s3-s1
      if [[ s4 -lt smin ]] 
      then
         let smin=s4
         SNAP_BEFORE="${snap_name}"
      fi
      #echo "b ${s4} ${smin}"
   fi

   # 
   # After Snapshot Logic ...
   #
   if [[ s1 -ge s3 ]] 
   then 
      let s4=s1-s3
      if [[ s4 -lt smax ]] 
      then
         let smax=s4
         SNAP_AFTER="${snap_name}"
      fi
      #echo "a ${s4} ${smax}"
   fi

   # 
   # Nearest Snapshot Logic ...
   #
   if [[ s4 -lt sdelta ]]
   then
      let sdelta=s4
      SNAP_DELTA="${snap_name}"
   fi
   #echo "${sdelta} ${s4} "
   #echo "Snap Before: ${SNAP_BEFORE}"
   #echo "Snap After: ${SNAP_AFTER}"
   #echo "Snap Nearest: ${SNAP_DELTA}"
else
   #echo "No Snapshots found for Timestamp, ${UTZ}, check script parameters. Exiting ..."
echo "{
  \"action\": \"${ACTION}\"
, \"database_name\": \"${SOURCE_SID}\"
, \"container_reference\": \"${CONTAINER_REFERENCE}\"
, \"provisionContainer\": \"${PARENT_REFERENCE}\"
, \"user_time\": \"${TZ}\"
, \"engine_time\": \"${UTZ}\"
, \"time_point\": \"${TIME_POINT}\"
, \"timeflow_name\": \"${FLOW_NAME_FOUND}\"
, \"timeflow_reference\": \"${FLOW_FOUND}\"
, \"timeflow_provisionable\": ${FLOW_PROVISIONABLE}
, \"before\": \"\"
, \"after\": \"\"
, \"nearest\": \"\"
, \"snapshot_result\": \"Error: No Snapshot found using ${PAGESIZE} pageSize and toDate ${TZA} for Timestamp ${UTZ}, Exiting ...\"
, \"snapshot_reference\": \"null\"
}"

   exit 1
fi
done <<< "${SNAP_NAMES}"

#echo "Snap Before: ${SNAP_BEFORE}"
#echo "Snap After: ${SNAP_AFTER}"
#echo "Snap Nearest: ${SNAP_DELTA}"

#
# Set the Return Values ...
#
# [ nearest | before | after ] ...
#
SNAP_TIME=""
if [[ "${TIME_POINT}" == "nearest" ]]
then 
   SNAP_TIME="${SNAP_DELTA}"
elif [[ "${TIME_POINT}" == "before" ]]
then
   SNAP_TIME="${SNAP_BEFORE}"
elif [[ "${TIME_POINT}" == "after" ]]
then
   SNAP_TIME="${SNAP_AFTER}"
else
   echo "Error: Invalid Time Point, ${TIME_POINT}, Exiting ..."
   exit 1
fi

#
# Get Snapshot Reference to Use ...
#
##echo "${STATUS}" | jq "."
SYNC_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SNAP_TIME}"'") | .reference '`

#
# Return Data ...
# 
echo "{ 
  \"action\": \"${ACTION}\"
, \"database_name\": \"${SOURCE_SID}\"
, \"container_reference\": \"${CONTAINER_REFERENCE}\"
, \"provisionContainer\": \"${PARENT_REFERENCE}\"
, \"user_time\": \"${TZ}\"
, \"engine_time\": \"${UTZ}\"
, \"time_point\": \"${TIME_POINT}\"
, \"timeflow_name\": \"${FLOW_NAME_FOUND}\"
, \"timeflow_reference\": \"${FLOW_FOUND}\"
, \"timeflow_provisionable\": ${FLOW_PROVISIONABLE}
, \"before\": \"${SNAP_BEFORE}\"
, \"after\": \"${SNAP_AFTER}\"
, \"nearest\": \"${SNAP_DELTA}\"
, \"difference\": \"${sdelta}\"
, \"snapshot_result\": \"${SNAP_TIME}\"
, \"snapshot_reference\": \"${SYNC_REF}\"
}"

exit 0

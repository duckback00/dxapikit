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
# Program Name : snapshot_details.sh
# Description  : Delphix API snapshot details with 
#                options to delete | keep_forever | keep_until  
# Author       : Alan Bitterman
# Created      : 2017-10-09
# Version      : v1.2 2019-05-22
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Include ./jqJSON_subroutines.sh
#  3.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  4.) Optional: Change Script Parameters 
#
# All Snapshots Usage:
#  ./snapshot_details.sh
#
# Snapshots Per dSource or VDB Usage:
# ./snapshot_details.sh [dSource_or_VDB] 
# ./snapshot_details.sh orcl
#
#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
## Parameters ...
 
SORT_BY="DESC"         # ASC=Ascending (earliest to latest) 
                       # DESC=Descending (latest to earliest)
 
#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

human_print(){
while read B dummy; do
if [[ "${B}" != "" ]] && [[ "${B}" != "null" ]]
then
  [ $B -lt 1024 ] && echo ${B} Bytes && break
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  echo $(((GB+512)/1024)) TB
fi
done
}

#########################################################
## Session and Login ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [[ "${RESULTS}" != "OK" ]]
then
   echo "Session Login Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get database container

echo "Reading Databases ... "
DBSTATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${DBSTATUS}" "status" )
#echo "${DBSTATUS}" | jq '.'

#
# Command Line Arguments ...
#
SOURCE_SID=$1				# dSource of VDB Name
CONTAINER_REFERENCE=""
#
# Get Database Container Reference iff Source Name is provided ...
#
if [[ "${SOURCE_SID}" != "" ]]
then
   echo "Source: ${SOURCE_SID}"
   CONTAINER_REFERENCE=`echo ${DBSTATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'" and .namespace==null) | .reference '`
   echo "Database Container Reference: ${CONTAINER_REFERENCE}"
   # 
   # Exit if reference not found ...
   #
   if [[ "${CONTAINER_REFERENCE}" == "" ]]
   then
     echo "Unable to find container reference for ${SOURCE_SID}, exiting ..."
     #
     # Help user with list of Valid Database Names ...
     #
     echo "Valid List of Database Names:"
     echo ${DBSTATUS} | jq --raw-output '.result | sort_by(.name) | .[].name'
     exit 1;
   fi
fi
#provisionContainer

#########################################################
## Get timeflows for this container ...

echo "Reading Timeflows ... "
#
# Need to read all timeflows for dependencies ...
#
#if [[ "${CONTAINER_REFERENCE}" == "" ]]
#then
   TFSTATUS=`curl -s -X GET -k ${BaseURL}/timeflow -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#else
#   TFSTATUS=`curl -s -X GET -k ${BaseURL}/timeflow?database=${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"` 
#fi
#echo "${TFSTATUS}" | jq '.'

#########################################################
## Get snapshots for this container ...

echo "Reading Snapshots ... "
#
# Get List of Snapshots per User Parameters ...
#
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   #
   # Get Snapshots for all Databases ...
   #
   STATUS=`curl -s -X GET -k ${BaseURL}/snapshot -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   if [[ "${SORT_BY}" == "DESC" ]]
   then
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | reverse | .[].reference'`
   else
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | .[].reference'`
   fi
else
   #
   # Get Snapshots for Individual Database ...
   #
   STATUS=`curl -s -X GET -k ${BaseURL}/snapshot?database=${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   if [[ "${SORT_BY}" == "DESC" ]]
   then
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | reverse | .[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .namespace==null) | .reference'`
   else
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | .[] | select(.container=="'"${CONTAINER_REFERENCE}"'" and .namespace==null) | .reference'`
   fi
fi
#echo "${STATUS}" | jq '.'
#echo "${SYNC_REFS}" | jq "."

#
# Loop through each snapshot, get size and report out ...
#
let j=0
let k=0
printf "%-12s | %-26s | %-10s | %-34s | %-15s | %s \n" "Database" "Snapshot Name" "Size" "Timeflow" "VDB Dependency" "Retention"
echo "-------------+----------------------------+------------+------------------------------------+-----------------+-----------"

while read i
do 
   #echo "$j $i"
   let j=j+1

   #
   # Snapshot Space/Size JSON String ...
   #
   json="{
    \"type\": \"SnapshotSpaceParameters\",
    \"objectReferences\": [
        \"${i}\"
   ]
}"

   #echo "JSON> $json"
   #echo "Snapshot Space ..."
   SPACE=`curl -s -X POST -k --data @- $BaseURL/snapshot/space -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

   #echo "$SPACE" | jq '.'
   CONTAINER_REFERENCE=`echo "${STATUS}" | jq --raw-output '.result[] | select(.reference=="'"${i}"'" and .namespace==null) | .container '`
   DBNAME=`echo "${DBSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${CONTAINER_REFERENCE}"'" and .namespace==null) | .name '`
   SNAME=`echo "${STATUS}" | jq --raw-output '.result[] | select(.reference=="'"${i}"'" and .namespace==null) | .name '`
   SIZE=`echo "${SPACE}" | jq '.result.totalSize' | human_print`

   #
   # Dependency ...
   #
   PARENT=`echo "${TFSTATUS}" | jq --raw-output '.result[] | select(.parentSnapshot=="'"${i}"'" and .namespace==null) | .name '`
   #echo "${i} Parent: ${PARENT}"
   if [[ "${PARENT}" != "" ]]
   then
      PDB_CONTAINER=`echo "${TFSTATUS}" | jq --raw-output '.result[] | select(.parentSnapshot=="'"${i}"'" and .namespace==null) | .container '`
      PDB_NAME=`echo "${DBSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${PDB_CONTAINER}"'" and .namespace==null) | .name '`
      DSTR="TF: ${PARENT}  VDB: $PDB_NAME "
   else
      let k=k+1
      DSTR=""
      PDB_NAME=""
   fi

   RETENTION=`echo "${STATUS}" | jq --raw-output '.result[] | select(.reference=="'"${i}"'" and .namespace==null) | .retention '`

   printf "%-12s | %-26s | %-10s | %-34s | %-15s | %s \n" "${DBNAME}" "${SNAME}" "${SIZE}" "${PARENT}" "${PDB_NAME}" "${RETENTION}" 

done <<< "${SYNC_REFS}"

#
# Prompt for Snapshot Name to perform operation on ... 
#
echo "Copy-n-paste Snapshot Name or enter to exit: "
read SNAP_NAME
if [[ "${SNAP_NAME}" == "" ]]
then
   echo "No Snapshot Name Provided ${SNAP_NAME}, Exiting ..."
   exit 1;
fi

SNAP_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SNAP_NAME}"'" and .namespace==null) | .reference '`
if [[ "${SNAP_REF}" == "" ]]
then
   echo "Error: Snapshot reference ${SNAP_REF} not found for Snapshot $SNAP_NAME, exiting ... "
   exit 1;
fi

#########################################################
## Action ...

ACTION=""		# default action ...
if [[ "${ACTION}" == "" ]]
then
   echo "---------------------------------"
   echo "NOTE: Snapshots with Timeflow/VDB Dependencies can not be deleted"
   echo "Options: [ delete | keep_forever | keep_until ] "
   echo "Please Enter Operation: "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
fi
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')

if [[ "${ACTION}" != "delete" ]] && [[ "${ACTION}" != "keep_forever" ]] && [[ "${ACTION}" != "keep_until" ]] 
then
   echo "Error: Invalid Action ${ACTION}, exiting ..."
   exit 1
fi

echo "Performing ${ACTION} on Snapshot ${SNAP_NAME} with reference ${SNAP_REF} ... "

#########################################################
## Get snapshot name to delete ...

if [[ "${ACTION}" == "delete" ]]
then
   #
   # Delete option iff not last snapshot and no dependencies ...
   #
   ## DEBUG ## echo "$j $k"
   if [[ $j -eq 1 ]] && [[ $k -eq 1 ]] 
   then
      echo "Last snapshot, delete not allowed ..."
   else
      #########################################################
      ## Delete snapshot ...

      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/snapshot/${SNAP_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

      echo "${STATUS}" | jq '.'
   fi              # end if not last snapshot ...
fi 		# end if delete ...

#########################################################
## Snapshot Keep Forever or Keep Until ...

if [[ "${ACTION}" == "keep_forever" ]] || [[ "${ACTION}" == "keep_until" ]]
then

   if [[ "${ACTION}" == "keep_until" ]]
   then
      echo "How many days to keep snapshot: "
      read DAYS
      if [ "${DAYS}" == "" ]
      then
         echo "No Days ${DAYS} Provided, Exiting ..."
         exit 1;
      fi
   else 
      DAYS="-1"
   fi

   json="{
     \"type\": \"OracleSnapshot\",
     \"retention\": ${DAYS}
   }"

   #echo "Updating Snapshot Retention ... "
   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/snapshot/${SNAP_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

   echo "${STATUS}" | jq '.'
fi 		# end if Keep Forever ...

############## E O F ####################################
echo " "
echo "Done "
exit 0;


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
# Description  : Delphix API snapshot details with delete  
# Author       : Alan Bitterman
# Created      : 2017-10-09
# Version      : v1.0.0
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
## Parameters ...
 
DELETE_OPT="TRUE"      # TRUE=allow  FALSE=don't allow
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
  [ $B -lt 1024 ] && echo ${B} Bytes && break
  KB=$(((B+512)/1024))
  [ $KB -lt 1024 ] && echo ${KB} KB && break
  MB=$(((KB+512)/1024))
  [ $MB -lt 1024 ] && echo ${MB} MB && break
  GB=$(((MB+512)/1024))
  [ $GB -lt 1024 ] && echo ${GB} GB && break
  echo $(((GB+512)/1024)) TB
done
}

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
## Get database container

echo "Reading Databases ... "
DBSTATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${DBSTATUS}" | jq '.'
RESULTS=$( jqParse "${DBSTATUS}" "status" )

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
   CONTAINER_REFERENCE=`echo ${DBSTATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
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

#########################################################
## Get timeflows for this container ...

echo "Reading Timeflows ... "
TFSTATUS=`curl -s -X GET -k ${BaseURL}/timeflow -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${TFSTATUS}" | jq '.'

#########################################################
## Get snapshots for this container ...

echo "Reading Snapshots ... "
STATUS=`curl -s -X GET -k ${BaseURL}/snapshot -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "${STATUS}" | jq '.'

#
# Get List of Snapshots per User Parameters ...
#
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   if [[ "${SORT_BY}" == "DESC" ]]
   then
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | reverse | .[].reference'`
   else
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | .[].reference'`
   fi
else
   if [[ "${SORT_BY}" == "DESC" ]]
   then
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | reverse | .[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .reference'`
   else
      SYNC_REFS=`echo "${STATUS}" | jq --raw-output '.result | sort_by(.name) | .[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .reference'`
   fi
fi

#
# Loop through each snapshot, get size and report out ...
#
let j=0
let k=0
printf "%-12s | %-26s | %-10s | %-34s | %s \n" "Database" "Snapshot Name" "Size" "Timeflow" "VDB"
echo "-------------+----------------------------+------------+------------------------------------+-------------"

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
   CONTAINER_REFERENCE=`echo "${STATUS}" | jq --raw-output '.result[] | select(.reference=="'"${i}"'") | .container '`
   DBNAME=`echo "${DBSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${CONTAINER_REFERENCE}"'") | .name '`
   SNAME=`echo "${STATUS}" | jq --raw-output '.result[] | select(.reference=="'"${i}"'") | .name '`
   SIZE=`echo "${SPACE}" | jq '.result.totalSize' | human_print`

   #
   # Dependency ...
   #
   PARENT=`echo "${TFSTATUS}" | jq --raw-output '.result[] | select(.parentSnapshot=="'"${i}"'") | .name '`
   #echo "${i} Parent: ${PARENT}"
   if [[ "${PARENT}" != "" ]]
   then
      PDB_CONTAINER=`echo "${TFSTATUS}" | jq --raw-output '.result[] | select(.parentSnapshot=="'"${i}"'") | .container '`
      PDB_NAME=`echo "${DBSTATUS}" | jq --raw-output '.result[] | select(.reference=="'"${PDB_CONTAINER}"'") | .name '`
      DSTR="TF: ${PARENT}  VDB: $PDB_NAME "
   else
      let k=k+1
      DSTR=""
      PDB_NAME=""
   fi

   #echo "---------------------------------"
   #echo "DB: ${DBNAME}  Snapshot: ${SNAME}  Size: ${SIZE}  ${DSTR} "
   printf "%-12s | %-26s | %-10s | %-34s | %s \n" ${DBNAME} ${SNAME} "${SIZE}" ${PARENT} ${PDB_NAME} 
 

done <<< "${SYNC_REFS}"

#########################################################
## Get snapshot name to delete ...

if [[ "${DELETE_OPT}" == "TRUE" ]]
then
   #
   # Delete option iff not last snapshot and no dependencies ...
   #
   ## DEBUG ## echo "$j $k"
   if [[ $j -eq 1 ]] && [[ $k -eq 1 ]] 
   then
      echo "Last snapshot, delete not allowed ..."
   else
      echo "NOTE: Snapshots with Timeflow/VDB Dependencies can not be deleted"
      echo "Copy-n-paste Snapshot Name to Delete or enter to exit: "
      read SNAP_DEL
      if [ "${SNAP_DEL}" == "" ]
      then
         echo "No Snapshot Name Provided ${SNAP_DEL}, Exiting ..."
         exit 1;
      fi

      #########################################################
      ## Delete snapshot ...

      SNAP_REF=`echo "${STATUS}" | jq --raw-output '.result[] | select(.name=="'"${SNAP_DEL}"'") | .reference '`
      echo "Deleting Snapshot $SNAP_DEL ... "
      if [[ "${SNAP_REF}" != "" ]]
      then
         STATUS=`curl -s -X POST -k --data @- ${BaseURL}/snapshot/${SNAP_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{}
EOF
`

         echo "${STATUS}" | jq '.'
      else
         echo "Error, unable to get snapshot reference from ${SNAP_DEL}, exiting ..."
         exit 1;
      fi
   fi              # end if not last snapshot ...
fi 		# end if DELETE_OPT ...
echo " "
echo "Done "
exit 0;


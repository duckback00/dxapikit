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
# Program Name : vdb_time.sh
# Description  : Delphix API Wrapper Script for Timeflows 
# Author       : Alan Bitterman
# Created      : 2019-05-30
# Version      : v1.0.2
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
#
# Wrapper Script to find the valid timeflow, snapshot for a user specified timestamp input ...
#
# Usage:
#  ./vdb_time.sh [refresh|rewind] [vdb_name] [timestamp] [snapshot|timeflow] [nearest|before|after]
#
# Examples: 
#  ./vdb_time.sh refresh VAppData "05/28 10am" snapshot nearest 
#  ./vdb_time.sh refresh VAppData "05/28 10am" timeflow                 # NOT Valid for non POINT IN TIME sources
#  ./vdb_time.sh rewind VAppData "05/28 10am" snapshot nearest
#  ./vdb_time.sh rewind VAppData "05/28 10am" timeflow			# NOT Valid for non POINT IN TIME sources
#
#
#  ./vdb_time.sh refresh VBITT "05/30 10am" snapshot nearest
#  ./vdb_time.sh refresh VBITT "05/30 10am" timeflow         
#  ./vdb_time.sh rewind VBITT "05/30 10am" snapshot nearest
#  ./vdb_time.sh rewind VBITT "05/30 10am" timeflow         
#
#

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Command Line Input ...
#
ACTION="${1}"
VDB="${2}"
TZ="${3}"
TIMEPOINT="${4}"
if [[ "${TIMEPOINT}" == "" ]]
then
   echo "Error: Invalid time point, use [ timeflow | snapshot ], exiting ..."
   exit 1
fi
LOCATION="${5}"
if [[ "${LOCATION}" == "" ]]
then
   LOCATION="nearest"
fi

#
# Snapshot ...
#
if [[ "${TIMEPOINT}" == "snapshot" ]]
then
   echo "./get_time_object.sh \"${ACTION}\" \"${VDB}\" \"${TZ}\" snapshot ${LOCATION}"
   RESULTS=`./get_time_object.sh "${ACTION}" "${VDB}" "${TZ}" snapshot ${LOCATION}`
   echo "${RESULTS}" | jq "."
#{
#  "database_name": "VBITT",
#  "container_reference": "ORACLE_DB_CONTAINER-48",
#  "user_time": "2019-05-23T03:30:00.000Z",
#  "engine_time": "2019-05-22T19:30:00.000Z",
#  "time_point": "nearest",
#  "timeflow_name": "DB_ROLLBACK@2019-05-20T12:27:56",
#  "timeflow_reference": "ORACLE_TIMEFLOW-61",
#  "timeflow_provisionable": true,
#  "before": "2019-05-20T16:30:16.609Z",
#  "after": "2019-05-23T07:18:31.266Z",
#  "nearest": "2019-05-23T07:18:31.266Z",
#  "difference": "878831266",
#  "snapshot_result": "2019-05-23T07:18:31.266Z",
#  "snapshot_reference": "ORACLE_SNAPSHOT-233"
#}
   FLOW=`echo "${RESULTS}" | jq -r ".timeflow_name"`
   SNAP=`echo "${RESULTS}" | jq -r ".snapshot_result"`
   #REF=`echo "${RESULTS}" | jq  -r".snapshot_reference"`
fi

#
# Timeflow Timestamp ...
#
if [[ "${TIMEPOINT}" == "timeflow" ]]
then
   echo "./get_time_object.sh \"${ACTION}\" \"${VDB}\" \"${TZ}\" timeflow"
   RESULTS=`./get_time_object.sh "${ACTION}" "${VDB}" "${TZ}" timeflow`
   echo "${RESULTS}" | jq "."

   #DT=`echo "${RESULTS}" | jq -r ".user_time"`
   DT=`echo "${RESULTS}" | jq -r ".engine_time"`
   FLOW=`echo "${RESULTS}" | jq -r ".timeflow_name"`
fi

#
# Refreshes ...
# 
if [[ "${ACTION}" == "refresh" ]] && [[ "${TIMEPOINT}" == "snapshot" ]]
then
   echo "./vdb_refresh_snapshot.sh ${VDB} ${FLOW} ${SNAP}"
   ./vdb_refresh_snapshot.sh ${VDB} ${FLOW} ${SNAP}
elif [[ "${ACTION}" == "refresh" ]] && [[ "${TIMEPOINT}" == "timeflow" ]]
then
   echo "./vdb_refresh_timestamp.sh ${VDB} ${FLOW} ${DT}"
   ./vdb_refresh_timestamp.sh ${VDB} ${FLOW} ${DT}

#
# Rewinds ...
#
elif [[ "${ACTION}" == "rewind" ]] && [[ "${TIMEPOINT}" == "snapshot" ]] 
then
   echo "./vdb_rollback_snapshot.sh ${VDB} ${FLOW} ${SNAP}"
   ./vdb_rollback_snapshot.sh ${VDB} ${FLOW} ${SNAP}
elif [[ "${ACTION}" == "rewind" ]] && [[ "${TIMEPOINT}" == "timeflow" ]]
then  
   echo "./vdb_rollback_timestamp.sh ${VDB} ${FLOW} ${DT}"
   ./vdb_rollback_timestamp.sh ${VDB} ${FLOW} ${DT}

#
# Invalid Input ...
# 
else
   echo "Error: Invalid Action - Time Point values, $ACTION ... $TIMEPOINT, exiting ... "
   exit 1
fi

exit 0


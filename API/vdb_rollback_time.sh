#!/bin/bash
#
# Usage:
# ./vdb_rollback_time.sh "VBITT" "05/24 10:30pm" timeflow
# ./vdb_rollback_time.sh "VBITT" "05/24 10:30pm" snapshot [nearest|before|after]
#

#
# Command Line Input ...
#
VDB="${1}"
TZ="${2}"
ACTION="${3}"
if [[ "${ACTION}" == "" ]]
then
   echo "Error: Invalid ACTION, use [ timeflow | snapshot ], exiting ..."
   exit 1
fi
LOCATION="${4}"
if [[ "${LOCATION}" == "" ]]
then
   LOCATION="nearest"
fi

#
# Rewind to Snapshot ...
#
if [[ "${ACTION}" == "snapshot" ]]
then
   RESULTS=`./get_time_object.sh "${VDB}" "${TZ}" snapshot ${LOCATION}`
   echo "${RESULTS}" | jq "."
#snapshot
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
   SNAP="@${SNAP}"

   echo "./vdb_rollback_snapshot.sh ${VDB} ${FLOW} ${SNAP}"
   ./vdb_rollback_snapshot.sh ${VDB} ${FLOW} ${SNAP}
fi


# 
# Rewind to Timestamp ...
#
if [[ "${ACTION}" == "timeflow" ]]
then
   RESULTS=`./get_time_object.sh "${VDB}" "${TZ}" timeflow`
   echo "${RESULTS}" | jq "."

#timeflow
#{
# "database_name": "VBITT"
#, "container_reference": "ORACLE_DB_CONTAINER-48"
#, "user_time": "2019-05-23T04:00:00.000Z"
#, "engine_time": "2019-05-22T20:00:00.000Z"
#, "timeflow_name": "DB_ROLLBACK@2019-05-20T12:27:56"
#, "timeflow_reference": "ORACLE_TIMEFLOW-61"
#, "timeflow_provisionable": true 
#}

   #DT=`echo "${RESULTS}" | jq -r ".user_time"`
   DT=`echo "${RESULTS}" | jq -r ".engine_time"`
   FLOW=`echo "${RESULTS}" | jq -r ".timeflow_name"`

   echo "./vdb_rollback_timestamp.sh ${VDB} ${FLOW} ${DT}"
   ./vdb_rollback_timestamp.sh ${VDB} ${FLOW} ${DT}
fi


#!/bin/bash

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
# Snapshot ...
#
if [[ "${ACTION}" == "snapshot" ]]
then
   echo "./get_time_object_parent.sh \"${VDB}\" \"${TZ}\" snapshot nearest"
   RESULTS=`./get_time_object_parent.sh "${VDB}" "${TZ}" snapshot nearest`
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
   SNAP="@${SNAP}"

   echo "./vdb_refresh_snapshot.sh ${VDB} ${FLOW} ${SNAP}"
   ./vdb_refresh_snapshot.sh ${VDB} ${FLOW} ${SNAP}
fi

#
# Timestamp ...
#
if [[ "${ACTION}" == "timeflow" ]]
then
   echo "./get_time_object_parent.sh \"${VDB}\" \"${TZ}\" timeflow"
   RESULTS=`./get_time_object_parent.sh "${VDB}" "${TZ}" timeflow`
   echo "${RESULTS}" | jq "."

   #DT=`echo "${RESULTS}" | jq -r ".user_time"`
   DT=`echo "${RESULTS}" | jq -r ".engine_time"`
   FLOW=`echo "${RESULTS}" | jq -r ".timeflow_name"`

   echo "./vdb_refresh_timestamp.sh ${VDB} ${FLOW} ${DT}"
   ./vdb_refresh_timestamp.sh ${VDB} ${FLOW} ${DT}
fi


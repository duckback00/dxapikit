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
# Copyright (c) 2018 by Delphix. All rights reserved.
#
# Program Name : dr_vdb.sh
# Description  : Delphix Reporting API Examples
# Author       : Alan Bitterman
# Created      : 2018-07-02
# Version      : v1.0
# Platforms    : ONLY works with Delphix Version 5.2.x or later
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Change values below as required
#
# Hard Code Defaults Usage:
# ./dr_vdb.sh
#
# Command Line Options Usage:
# ./dr_vdb.sh [vdb_name] [engine]
# ./dr_vdb.sh Vorcl 172.16.160.195
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

DRIP="172.16.160.135"		# Delphix Reporting Server IP Address/FullyQualified Hostname
DRUSR="delphix_admin"		# Delphix Reporting User Account
DRPWD="delphix"			# Delphix Reporting User Password

#
# Show Report Data Results for ... 
#
VDB="${1}"
if [[ "${VDB}" ==  "" ]]
then
   echo "Using hard coded default ..." 
   VDB="Vorc_560"
fi
ENGINE="${2}"
if [[ "${ENGINE}" == "" ]]
then
   echo "Using hard coded default ..."
   ENGINE="172.16.160.195"
fi
#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

# Output Variables ...
DT=`date '+%Y%m%d%H%M%S'`
DELIM=","
HCSV="CurrentTime${DELIM}VDB${DELIM}Engine"
CSV="${DT}${DELIM}${VDB}${DELIM}${ENGINE}"
OUTFILE="${VDB}_${ENGINE}_${DT}.csv"

#########################################################
## jq ...

JQ=`which jq`
if [[ "${JQ}" == "" ]] 
then
   echo "Please enter toolkit path: "
   read TKP
   TKP=`echo $TKP | grep -v ^$`
   echo "Toolkit Path: ${TKP}"
   # ./toolkit/Delphix_COMMON_420e34b0_0ce8_4555_3f82_6a8d25e540bb_oracle_host/scripts/jq/linux_x86/bin64/jq
   list=$(find ${TKP} -name "*jq" | grep "linux_x86/bin64")
   #echo "$list"
   for i in "$list"; do 
      if [[ "${i}" != "" ]] 
      then
         JQ=`echo "${i}" | grep -v ^$` 
      fi
   done
fi
if [[ "${JQ}" == "" ]]
then
   echo "ERROR: Unable to find jq, the JSON Command Line Utility ..."
   echo "Either install the utility or run on a Delphix Source or Target server"
   echo "Exiting ..."
   exit 1
fi
echo "jq: ${JQ}"

#########################################################
## Authentication ...

echo "Authenticating URL: http://${DRIP}/api/login ..."
STATUS=`curl -s --data "password=${DRPWD}&user=${DRUSR}" http://${DRIP}/api/login`
#echo "${STATUS}" | ${JQ} "."
RESULTS=`echo "${STATUS}" | ${JQ} -r ".success"`
if [[ "${RESULTS}" != "true" ]] 
then 
   echo "${STATUS}" | ${JQ} "."
   echo "Error in authentication, exiting ..."
   exit 1
fi

#
# Parse results to get authentication key and userid ...
#
KEY=`echo "${STATUS}" | ${JQ} -r ".loginToken"`
USERID=`echo "${STATUS}" | ${JQ} -r ".userId"`

echo "Authentication Key: ${KEY}"
echo "Authentication UserId: ${USERID}"

#########################################################
## List Reports ...

#echo "List Reports ..."
#STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/list_reports"`
#echo "${STATUS}" | ${JQ} "."

# echo "${STATUS}" | ${JQ} -r ".[] | ._id"
# result_js_bookmark_usage
# result_table_capacity_breakdown
# result_active_faults
# result_vdb_invt
# result_audit
# result_recent_alerts
# result_snapsync_summary
# result_replication_status
# result_engine_summary
# result_storage_summary
# result_vdb_usge
# result_recent_jobs
# result_dsource_usage
# result_vdb_refresh
# 
#   {
#     "_id": "result_storage_summary",
#     "name": "Storage Summary",
#     "script": "storage-summary.js"
#   },
 
#########################################################
## VDB Invetory ...

RPTID="result_vdb_invt"
echo "Report Data for: ${RPTID}"
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/get_report?report=${RPTID}"`
#echo "${STATUS}" | ${JQ} "."

#    "_id": "ORACLE_DB_CONTAINER-187@172.16.160.195",
#    "_delphixEngineId": "172.16.160.195",
#    "name": "Vorc_560",
#    "provisionContainer": "orcl",
#    "creationTime": "2018-06-29T10:05:44.410Z",
#    "enabled": "ENABLED",
#    "status": "UNKNOWN",
#    "containerType": "Oracle 11.2.0.4.0",
#    "repoVersion": "11.2.0.4.0",
#    "parentPoint": "33426506",
#    "tag": ""

PARENT=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .provisionContainer"`
CTIME=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .creationTime"`
STAT=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .status"`

echo "Parent: ${PARENT}"
echo "Creation Time: ${CTIME}"
echo "Status: ${STAT}"

HCSV="${HCSV}${DELIM}Parent${DELIM}Creation Time${DELIM}Status"
CSV="${CSV}${DELIM}${PARENT}${DELIM}${CTIME}${DELIM}${STAT}"

#########################################################
## VDB Usage ...

RPTID="result_vdb_usge"
echo "Report Data for: ${RPTID}"
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/get_report?report=${RPTID}"`
#echo "${STATUS}" | ${JQ} "."

#    "_id": "ORACLE_DB_CONTAINER-187@172.16.160.195",
#    "_delphixEngineId": "172.16.160.195",
#    "name": "Vorc_560",
#    "lastRefresh": "2018-06-29T10:05:44.410Z",
#    "unvirtualizedSpace": 18942608384,
#    "actualSpace": 4333056,
#    "ratio": 99.97712534666736,
#    "tag": ""

LASTREFRESH=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .lastRefresh"`
UNVSPACE=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .unvirtualizedSpace"`
ACTSPACE=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .actualSpace"`
RATIO=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .ratio"`

echo "Last Refresh: ${LASTREFRESH}"
echo "Unvirtualized Space: ${UNVSPACE}"
echo "Actual Space: ${ACTSPACE}"
echo "Ratio: ${RATIO}"

HCSV="${HCSV}${DELIM}Last Refresh${DELIM}Unvirtualized Space${DELIM}Actual Space${DELIM}Ratio"
CSV="${CSV}${DELIM}${LASTREFRESH}${DELIM}${UNVSPACE}${DELIM}${ACTSPACE}${DELIM}${RATIO}"

#########################################################
## VDB Refreshes ...

RPTID="result_vdb_refresh"
echo "Report Data for: ${RPTID}"
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/get_report?report=${RPTID}"`
#echo "${STATUS}" | ${JQ} "."

#    "_id": "ORACLE_DB_CONTAINER-187@172.16.160.195",
#    "_delphixEngineId": "172.16.160.195",
#    "name": "Vorc_560",
#    "tag": "",
#    "jobsLastMonth": 1,
#    "jobsLastWeek": 1,
#    "lastJobDuration": 133024,
#    "lastJobTime": "2018-06-29T10:33:27.258Z",
#    "averageJobDuration": 133024

JOBTIME=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .lastJobTime"`
JOBDURATION=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .lastJobDuration"`
AVGDURATION=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .averageJobDuration"`
LASTWEEK=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .jobsLastWeek"`
LASTMONTH=`echo "${STATUS}" | ${JQ} -r ".[] | select (.name==\"${VDB}\" and ._delphixEngineId==\"${ENGINE}\") | .jobsLastMonth"`

echo "Last Refresh Time: ${JOBTIME}"
echo "Last Refresh Duration: ${JOBDURATION}"
echo "Average Refresh Duration: ${AVGDURATION}"
echo "Last Week: ${LASTWEEK}"
echo "Last Month: ${LASTMONTH}"

HCSV="${HCSV}${DELIM}Last Refresh Time${DELIM}Last Refresh Duration${DELIM}Average Refresh Duration${DELIM}Last Week${DELIM}Last Month"
CSV="${CSV}${DELIM}${JOBTIME}${DELIM}${JOBDURATION}${DELIM}${AVGDURATION}${DELIM}${LASTWEEK}${DELIM}${LASTMONTH}"

#########################################################
## Logout ...

#STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/logout"`
#echo "${STATUS}" | ${JQ} "."

#########################################################
## Write Out CSV File ...

echo "${HCSV}" > ${OUTFILE}
echo "${CSV}" >> ${OUTFILE}

#########################################################
## The End is Here ...
echo "Done ..."
exit 0


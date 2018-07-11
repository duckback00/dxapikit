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
# Program Name : dr_dump_all.sh
# Description  : Delphix Reporting API Examples
# Author       : Alan Bitterman
# Created      : 2018-07-11
# Version      : v1.0
# Platforms    : ONLY works with Delphix Version 5.2.x or later
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Change values below as required
#
# Usage:
# ./dr_dump_all.sh 
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

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

# Output Variables ...
DT=`date '+%Y%m%d%H%M%S'`
OUTFILE="DumpAll_${DRIP}_${DT}.json"

echo "{ 
  \"timeStamp\": \"${DT}\"
, \"report_server\": \"${DRIP}\" " > ${OUTFILE}

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

echo "Reports ..."
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/list_reports"`
#echo "${STATUS}" | ${JQ} "."

RPTLIST=`echo "${STATUS}" | ${JQ} -r ".[] | ._id"`

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
## Loop through each Report ...


let k=0
while read rid
do
   STATUS=""
   let k=k+1
   echo "$k ... $rid "
   STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/get_report?report=${rid}"`
   echo ", \"${rid}\": 
 ${STATUS} " >> ${OUTFILE}
done <<< "${RPTLIST}"

echo "}" >> ${OUTFILE}
echo "JSON Dump File: ${OUTFILE}"

#########################################################
## Logout ...

#STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/logout"`
#echo "${STATUS}" | ${JQ} "."

#########################################################
## The End is Here ...
echo "Done ..."
exit 0


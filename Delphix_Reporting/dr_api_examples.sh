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
# Program Name : dr_api_examples.sh
# Description  : Delphix Reporting API Examples
# Author       : Alan Bitterman
# Created      : 2018-06-14
# Version      : v1.0
# Platforms    : ONLY works with Delphix Version 5.2.x or later
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Change values below as required
#
# Usage:
# ./dr_api_examples.sh
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

DRIP="172.16.160.133"		# Delphix Reporting Server IP Address/FullyQualified Hostname
DRUSR="delphix_admin"		# Delphix Reporting User Account
DRPWD="delphix"			# Delphix Reporting User Password

#
# Show Report Data Results for ... 
#
#RPTNME="Storage Summary"	# if empty, array[1] value report returned will be used
RPTNME=""			# if empty, array[1] value report returned will be used

#
# Add a Delphix Engine ...
#
DEHOST="54.205.223.197"		# Delphix Engine IP Address/FullyQualified Hostname
DEUSER="delphix_engine"		# Delphix Engine User Name 
DEPASS="delphix"		# Delphix Engine User Password

# 
# Remove Delphix Engine Option after Adding ...
#
REMOVE_DEHOST="54.205.223.197"		# "" or specify hostname ...


#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

echo "Authenticating URL: http://${DRIP}/api/login ..."
STATUS=`curl -s --data "password=${DRPWD}&user=${DRUSR}" http://${DRIP}/api/login`
#echo "${STATUS}" | jq "."
RESULTS=`echo "${STATUS}" | jq -r ".success"`
if [[ "${RESULTS}" != "true" ]] 
then 
   echo "${STATUS}" | jq "."
   echo "Error in authentication, exiting ..."
   exit 1;
fi

#
# Parse results to get authentication key and userid ...
#
KEY=`echo "${STATUS}" | jq -r ".loginToken"`
USERID=`echo "${STATUS}" | jq -r ".userId"`

echo "Authentication Key: ${KEY}"
echo "Authentication UserId: ${USERID}"

#########################################################
## List Reports ...

echo "List Reports ..."
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/list_reports"`
echo "${STATUS}" | jq "."

# echo "${STATUS}" | jq -r ".[] | ._id"
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
 
#
# Get Report Name and Id ...   # RPTNME defined earlier ...
#
if [[ "${RPTNME}" != "" ]]
then
   RPTID=`echo "${STATUS}" | jq -r ".[] | select (.name==\"${RPTNME}\") | ._id "`
else
   RPTID=`echo "${STATUS}" | jq -r ".[1]._id "`
   RPTNME=`echo "${STATUS}" | jq -r ".[1].name "`
fi
echo "Report Name: ${RPTNME}"
echo "Report Id: ${RPTID}"

#
# Fetching Report Data
#
echo "Report Data for ${RPTNME} ..."
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/get_report?report=${RPTID}"`
echo "${STATUS}" | jq "."

#echo "${STATUS}" | jq -r ".[] | select (._delphixEngineId==\"${ENGID}\") "
#echo "${STATUS}" | jq -r ".[] | select (._delphixEngineId==\"${ENGID}\") | .storageFree "

#   {
#     "_id": "172.16.160.195",
#     "_delphixEngineId": "172.16.160.195",
#     "storageTotal": 30685478912,
#     "storageUsed": 11169971712,
#     "vdbCount": 0,
#     "dsourceCount": 1,
#     "totalObjects": 1,
#     "storageFree": 19515507200,
#     "storageUsedPct": 36.40149056833466,
#     "storageSaved": 9716625408,
#     "tag": ""
#   },

#########################################################
## Add Engine ...

if [[ "${DEHOST}" != "" ]]
then
   echo "Adding Delphix Engine ${DEHOST} ..." 
   STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/add_engine?hostname=${DEHOST}&user=${DEUSER}&password=${DEPASS}"`
   echo "${STATUS}" | jq "."
fi

#########################################################
## List Engines ...

echo "Listing Delphix Engines ... "
STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/list_engines"`
echo "${STATUS}" | jq "."

ENGID=`echo ${STATUS} | jq -r ".[] | select (._id==\"${DEHOST}\") | ._id"`
echo "New Engine Id: ${ENGID}"

#  { 
#    "_id": "172.16.160.195",
#    "version": "Delphix Engine 5.2.4.0",
#    "tag": "",
#    "status": "Connected"
#  },

#########################################################
## Removing a Delphix Engine

if [[ "${REMOVE_DEHOST}" != "" ]]
then
   echo "Removing Delphix Engine ${REMOVE_DEHOST} ... "
   STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/remove_engine?hostname=${REMOVE_DEHOST}"`
   echo "${STATUS}" | jq "."
fi

#########################################################
## Logout ...

# STATUS=`curl -s -H "X-Login-Token: ${KEY}" -H "X-User-Id: ${USERID}" "http://${DRIP}/api/logout"`
# echo "${STATUS}" | jq "."

#########################################################
## The End is Here ...
echo "Done ..."
exit 0


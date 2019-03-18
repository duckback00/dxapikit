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
# Program Name : sample.sh
# Description  : Simple DXM-Toolkit Example
# Author       : Alan Bitterman
# Created      : 2019-03-15
# Version      : v1.0
#
# Requirements :
#  1.) dxmc executable from dxm-toolkit 
#  2.) jq command line libraries
#  3.) Change values below as required
#
# Usage:
# ./sample.sh
#
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

#
# DDDP Connection ... 
#
DE="de2"
DMIP="172.16.160.195"
#DMIP="10.0.1.10"
DMUSER="Admin"
DMPASS="Admin-12"
APP="dxmc_app"
ENV="dxmc_env"

# 
# Database Connector ...
#
CNAME="Conn3"
USR="delphixdb"
USR=`echo "${USR}" | tr '[:lower:]' '[:upper:]'`
PWD="delphixdb"
DBT="ORACLE"
DBT=`echo "${DBT}" | tr '[:upper:]' '[:lower:]'`
HOST="172.16.160.133"
PORT="1521"
SCHEMA="delphixdb"
SCHEMA=`echo "${SCHEMA}" | tr '[:lower:]' '[:upper:]'`
SID="orcl"

#
# Other Object Names ...
#
RSNAME="RuleSet3"
MASKNAME="emp_mask"

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Add Engine Configuration ...
#
#dxmc engine list 
RESULTS=`dxmc engine list --format json`
CHK=`echo "$RESULTS" | jq -r  '.[] | select(."Engine name"=="'${DE}'") '`
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc engine add --engine ${DE} --ip ${DMIP} --username ${DMUSER} --password ${DMPASS} --default Y`
   echo "${RESULTS}"
else
   echo "Engine \"${DE}\" Already Exists ..."  #"${CHK}"
fi

#
# Add Application ...
# 
RESULTS=`dxmc application list --engine ${DE} --format json`
#echo "${RESULTS}"
CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Application name"=="'${APP}'" and ."Engine name"=="'${DE}'") '`
#{ "Application name": "profile_app", "Engine name": "de" }
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc application add --appname ${APP} --engine ${DE}`
   echo "${RESULTS}"
   #Application ${APP} added
else
   echo "Application \"${APP}\" Already Exists ..."
fi   

#
# Add Environment ...
# 
RESULTS=`dxmc environment list --engine ${DE} --format json`
#echo "${RESULTS}"
CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Environment name"=="'${ENV}'" and ."Application name"=="'${APP}'" and ."Engine name"=="'${DE}'") '`
if [[ "${CHK}" == "" ]]
then 
   RESULTS=`dxmc environment add --envname ${ENV} --appname ${APP} --purpose MASK --engine ${DE}`
   echo "${RESULTS}"
   #Environment ${ENV} added
else
   echo "Environment \"${ENV}\" Already Exists ..."
fi   

#
# Delete All Connectors in Environment ... 
# 
RESULTS=`dxmc connector list --envname ${ENV} --engine ${DE} --format json`
#echo "|${RESULTS}|"
if [[ ! "${RESULTS}" =~ "No connectors found" ]]
then
   CHK=`echo "${RESULTS}" | jq -r  '.[] | select(."Environment name"=="'${ENV}'" and ."Engine name"=="'${DE}'") | ."Connector name"'`
   #echo "${CHK}"
   while read line
   do
      #echo "|${line}|"
      #echo "dxmc connector delete --connectorname ${line} --envname ${ENV} --engine ${DE}"
      CMD="dxmc connector delete --connectorname ${line} --envname ${ENV} --engine ${DE}"
      RESULTS=`${CMD}`
      echo "${RESULTS}"
   done <<< "${CHK}"
fi

#
# Add Database Connector ...
#
echo "Adding Database Connector ${CNAME} ..."
RESULTS=`dxmc connector list --envname ${ENV} --engine ${DE} --format json`
#echo "${RESULTS}"
if [[ "${RESULTS}" =~ "No connectors found" ]]
then
   CMD="dxmc connector add --connectorname ${CNAME} --envname ${ENV} --connectortype ${DBT} --host ${HOST} --port ${PORT} --username ${USR} --password ${PWD} --schemaname ${SCHEMA} --sid ${SID} --engine ${DE}"
   RESULTS=`${CMD}`
   echo "${RESULTS}"
fi

# 
# Test Connector ...
#
echo "Testing Connector ${CNAME} ..."
RESULTS=`dxmc connector test --envname ${ENV} --engine ${DE}  --connectorname ${CNAME}  --format json`
echo "${RESULTS}"
if [[ ! "${RESULTS}" =~ "succeeded" ]]
then
   echo "Error: Connector Test was not Successful, please validate and try again. Exiting ..."
   exit 1
fi

#
# Fetch all tables ...
#
echo "Fetching Connector Tables ..."
RESULTS=`dxmc connector fetch_meta --envname ${ENV} --connectorname ${CNAME} --engine ${DE} --format json`
echo "${RESULTS}"

#
# Optional: Write Tablenames to a CSV File ...
#

#
# Add RuleSet ...
#
echo "Adding Rule Sert ${RSNAME} ..."
RESULTS=`dxmc ruleset add --rulesetname ${RSNAME} --connectorname ${CNAME} --envname ${ENV} --engine ${DE}`
echo "${RESULTS}"

#
# Add Individual Tables ...
#
RESULTS=`dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname EMPLOYEES`
echo "${RESULTS}"

#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname MEDICAL_RECORDS
#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname PATIENT
#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --metaname PATIENT_DETAILS

#
# OR Batch load meta data via CSV file created earlier or by user ...
#
#cat tbl.csv
## tablename, custom_sql, where_clause, having_clause, key_column
#EMP,,,,
#DEPT,,,,
#SALGRADE,,,,
#TEST,,,,
#...

#dxmc ruleset addmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --inputfile tbl.csv
 
#
# List Rule Set Meta Data ...
#
echo "RuleSet Metadata ..."
RESULTS=`dxmc ruleset listmeta --rulesetname ${RSNAME} --envname ${ENV} --engine ${DE} --format json`
echo "${RESULTS}"

#
# Algorithms ...
#
#echo "Column List ..."
#RESULTS=`dxmc column list --rulesetname ${RSNAME} --envname ${ENV} --format json`
#echo "${RESULTS}"

echo "Adding Algorithms ..."

RESULTS=`dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname FIRST_NAME --algname FirstNameLookup --domainname FIRST_NAME`
#echo "${RESULTS}"

RESULTS=`dxmc column setmasking --rulesetname ${RSNAME} --envname ${ENV} --columnname LAST_NAME --algname LastNameLookup --domainname LAST_NAME`
#echo "${RESULTS}"

echo "Column List ..."
RESULTS=`dxmc column list --rulesetname ${RSNAME} --envname ${ENV} --format json`
echo "${RESULTS}"


echo "Create Masking Job ..."
RESULTS=`dxmc job add --jobname ${MASKNAME} --envname ${ENV} --rulesetname ${RSNAME}`
echo "${RESULTS}"

#echo "List Masking Jobs ..."
#RESULTS=`dxmc job list --format json`
#echo "${RESULTS}"

echo "Execute Masking Job ${MASKNAME} ..."
RESULTS=`dxmc job start --jobname ${MASKNAME} --envname ${ENV}`
echo "${RESULTS}"

############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


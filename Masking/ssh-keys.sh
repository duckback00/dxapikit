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
# Program Name : ssh-keys.sh
# Description  : Load SFTP ssh keys into the Masking Engine 
# Author       : Alan Bitterman
# Created      : 2019-04-02
# Version      : v1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Delphix/Masking Engine version 5.2.# or later 
#
# Interactive Usage:
# ./ssh-keys.sh
#
# Non-Interactive Usage:
# ./ssh-keys.sh [add|delete] [keyfile]
#
#########################################################
## Delphix Masking Parameter Initialization ...

###. ./masking_engine.conf
#
# Masking Engine Connection Parameters ...
#
DMIP=172.16.160.195
DMPORT=8282
DMUSER="admin"
DMPASS="Admin-12"
DMURL="http://${DMIP}:${DMPORT}/masking/api"
DELAYTIMESEC=10
DT=`date '+%Y%m%d%H%M%S'`

#########################################################
## Authentication ...

STATUS=`curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{ \"username\": \"${DMUSER}\", \"password\": \"${DMPASS}\" }" "${DMURL}/login"`
#echo ${STATUS} | jq "."
KEY=`echo "${STATUS}" | jq --raw-output '.Authorization'`
echo "Authentication Key: ${KEY}"

#########################################################
## Get Existing ssh-keys ...

STATUS=`curl -s -X GET --header "Accept: application/json" --header "Authorization: ${KEY}" "${DMURL}/ssh-keys"`
echo "Existing ssh-keys: "
echo "${STATUS}" | jq -r ".[].sshKeyName"

#########################################################
## Command Line Arguments ...

#
# Action ...
#
ACTION=${1}
if [[ "${ACTION}" == "" ]] 
then
   echo "Enter Action [ add | delete ]: "
   read ACTION
fi
ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')

case ${ACTION} in
add)
;;
delete)
;;
*)
  echo "Unknown option (add | delete): ${ACTION}"
  echo "Exiting ..."
  exit 1;
;;
esac

#
# SSH Key File ...
#
if [[ "${ACTION}" == "add" ]]
then
   KEYFILE=${2}
   if [[ "${KEYFILE}" == "" ]]
   then
      echo "Enter ssh-key filename (full path/name): "
      read KEYFILE
   fi
   if [[ ! -f "${KEYFILE}" ]] 
   then
      echo "Key File ${KEYFILE} does not exist please verify, exiting ..."
      exit 1
   fi
   STATUS=`curl -s -X POST --header 'Content-Type: multipart/form-data' --header 'Accept: application/json' --header "Authorization: ${KEY}" -F "sshKey=@${KEYFILE}" "${DMURL}/ssh-keys"`
   echo "${STATUS}" | jq "."
fi

if [[ "${ACTION}" == "delete" ]]
then
   KEYFILE=${2}
   if [[ "${KEYFILE}" == "" ]]
   then
      echo "Enter existing ssh-key name: "
      read KEYFILE
   fi

   FOUND=`echo "${STATUS}" | jq ".[] | select (.sshKeyName==\"${KEYFILE}\") | .sshKeyName "`
   if [[ "${FOUND}" != "" ]] 
   then
      STATUS=`curl -s -X DELETE --header 'Accept: application/json' --header "Authorization: ${KEY}" "${DMURL}/ssh-keys/${KEYFILE}"`
      echo "${STATUS}" | jq "."
   else
      echo "Key Name ${KEYFILE} does not exist please verify, exiting ..."
      exit 1
   fi 
fi

echo "Done ..."
exit


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
# Program Name : vdb_ase_init.sh 
# Description  : Delphix APIs for init operations on ASE VDBs
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Usage: ./vdb_ase_init.sh
#
# Delphix Doc's Reference:
#    https://docs.delphix.com/pages/viewpage.action?pageId=51970750
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
#
# Command Line Arguments ...
#
# $1 = start | stop | disable | enable | status | delete

ACTION=$1
if [[ "${ACTION}" == "" ]] 
then
   echo "Usage: ./vdb_init.sh [start | stop | enable | disable | status | delete] [VDB_Name] "
   echo "Please Enter Init Option : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
   ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
fi

SOURCE_SID="$2"
if [[ "${SOURCE_SID}" == "" ]]
then
   echo "Please Enter dSource or VDB Name (case sensitive): "
   read SOURCE_SID
   if [ "${SOURCE_SID}" == "" ]
   then
      echo "No dSource or VDB Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export SOURCE_SID

#########################################################
## Authentication ...

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

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "database container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Get source reference ... 

STATUS=`curl -s -X GET -k ${BaseURL}/source -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#
# Parse out source reference from container reference using jq ...
#
VDB=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .reference '`
echo "source reference: ${VDB}"
if [ "${VDB}" == "" ]
then
  echo "ERROR: unable to find source reference in ... $STATUS"
  echo "Exiting ..."
  exit 1;
fi

#echo "${STATUS}"
#echo " "
VENDOR_SOURCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${CONTAINER_REFERENCE}"'") | .type '`
echo "vendor source: ${VENDOR_SOURCE}"

#########################################################
#
# start or stop the vdb based on the argument passed to the script
#
case ${ACTION} in
start)
;;
stop)
;;
enable)
;;
disable)
;;
status)
;;
delete)
;;
*)
  echo "Unknown option (start | stop | enable | disable | status | delete): ${ACTION}"
  echo "Exiting ..."
  exit 1;
;;
esac

#
# Execute VDB init Request ...
#
if [ "${ACTION}" == "status" ]
then

   # 
   # Get Source Status ...
   #
   STATUS=`curl -s -X GET -k ${BaseURL}/source/${VDB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   echo "curl -s -X GET -k ${BaseURL}/source/${VDB} -b \"${COOKIE}\" -H \"${CONTENT_TYPE}\" "
   #echo ${STATUS}
   #echo ${STATUS} | jq --raw-output '.'
   #
   # Parse and Display Results ...
   #
   r=`echo ${STATUS} | jq --raw-output '.result.runtime.status'`
   #r1=`echo ${STATUS} | jq --raw-output '.result.enabled'`
   r1=`echo ${STATUS} | jq --raw-output '.result.runtime.enabled'`
   echo "Runtime Status: ${r}"
   echo "Enabled: ${r1}"

else

   # 
   # delete ...
   #
   if [ "${ACTION}" == "delete" ]
   then

      if [[ ${VENDOR_SOURCE} == Oracle* ]]
      then 
         deleteParameters="OracleDeleteParameters"
      else
         deleteParameters="DeleteParameters"
      fi
      echo "delete parameters type: ${deleteParameters}"

      STATUS=`curl -s -X POST -k --data @- ${BaseURL}/database/${CONTAINER_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "${deleteParameters}"
}
EOF
`

   else

      # 
      # All other init options; start | stop | enable | disable ...
      #

      #
      # Submit VDB init change request ...
      #
      STATUS=`curl -s -X POST -k ${BaseURL}/source/${VDB}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}"`

   fi      # end if delete ...

   #########################################################
   #
   # Get Job Number ...
   #
   JOB=$( jqParse "${STATUS}" "job" )
   echo "Job: ${JOB}"

   jqJobStatus "${JOB}"            # Job Status Function ...

fi     # end if $status

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


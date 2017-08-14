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
# Program Name : group_operations.sh
# Description  : Delphix API for groups
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.1 2017-08-14
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#
# Interactive Usage: ./group_operations.sh
#
# Non-Interactive Usage: ./group_operations.sh [create | delete] [Group_Name]
#
# Sample script to create or delete a Delphix Engine Group object ... 
#
#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get List of Existing Group Names ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "group: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

#########################################################
#
# Command Line Arguments ...
#
ACTION=$1
if [[ "${ACTION}" == "" ]]
then
   echo "Please Enter Group Option [create | delete] : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
   ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
fi
export ACTION

DELPHIX_GRP="$2"
if [[ "${DELPHIX_GRP}" == "" ]]
then
   #
   # Parse out group names ...
   #
   GROUP_NAMES=`echo ${STATUS} | jq --raw-output '.result[] | .name '`
   echo "Existing Group Names: "
   echo "${GROUP_NAMES}"

   echo "Please Enter Group Name (case sensitive): "
   read DELPHIX_GRP
   if [ "${DELPHIX_GRP}" == "" ]
   then
      echo "No Group Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export DELPHIX_GRP

#########################################################
## Get Group Reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

#
# Parse out container reference for name of $DELPHIX_GRP ...
#
GROUP_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DELPHIX_GRP}"'") | .reference '`
echo "group reference: ${GROUP_REFERENCE}"

#########################################################
#
# create or delete the group based on the argument passed to the script
#
case ${ACTION} in
create)
;;
delete)
;;
*)
  echo "Unknown option (create | delete): $ACTION"
  echo "Exiting ..."
  exit 1;
;;
esac

#
# Execute VDB init Request ...
#
if [ "${ACTION}" == "create" ] && [ "${GROUP_REFERENCE}" == "" ]
then
   # 
   # Create Group ...
   #
   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
   "type": "Group",
   "name": "${DELPHIX_GRP}"
}
EOF
`

elif [ "${ACTION}" == "create" ] && [ "${GROUP_REFERENCE}" != "" ]
then
   echo "Warning: Group Name ${DELPHIX_GRP} already exists ..."
fi	# end if create ...

# 
# delete ...
#
if [ "${ACTION}" == "delete" ] && [ "${GROUP_REFERENCE}" != "" ]
then
   STATUS=`curl -s -X POST -k --data @- ${BaseURL}/group/${GROUP_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
}
EOF
`

elif [ "$1" == "delete" ] && [ "${GROUP_REFERENCE}" == "" ]
then
   echo "Warning: Group Name ${DELPHIX_GRP} does not exist ..."
fi      # end if delete ...


#########################################################
#
# Get Job Number ...
#
RESULTS=$( jqParse "${STATUS}" "status" )
echo "${ACTION} Status: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Check coding ... ${STATUS}"
   echo "Exiting ..."
   exit 1;
fi

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


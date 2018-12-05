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
# Program Name : jqJSON_subroutines.sh
# Description  : Shell Script Subroutines Commonly Used by API scripts
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.1.0
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#

################################################################
#
# This code requires the jq Linux/Mac JSON parser program ...
# 


jqParse() {
   STR=$1                  # json string
   FND=$2                  # name to find
   RESULTS=""              # returned name value
   RESULTS=`echo $STR | jq --raw-output '.'"$FND"''`
   #echo "Results: ${RESULTS}"
   if [ "${FND}" == "status" ] && [ "${RESULTS}" != "OK" ]
   then
      echo "Error: Invalid Satus, please check code ... ${STR}"
      exit 1;
   elif [ "${RESULTS}" == "" ]
   then 
      echo "Error: No Results ${FND}, please check code ... ${STR}"
      exit 1;
   fi   
   echo "${RESULTS}"
}  


#
# Session and Login ...
#
RestSession() {
  DMUSER=$1               # Username
  DMPASS=$2               # Password
  BaseURL=$3              #
  COOKIE=$4               #
  CONTENT_TYPE=$5         #

   STATUS=`curl -s -X POST -k --data @- $BaseURL/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 9,
        "micro": 0
    }
}
EOF
`

   #echo "Session: ${STATUS}"
   RESULTS=$( jqParse "${STATUS}" "status" )

   STATUS=`curl -s -X POST -k --data @- $BaseURL/login -b "${COOKIE}" -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LoginRequest",
    "username": "${DMUSER}",
    "password": "${DMPASS}"
}
EOF
`

   #echo "Login: ${STATUS}"
   RESULTS=$( jqParse "${STATUS}" "status" )

   echo $RESULTS
}


#########################################################
## Get API Version Info ...

jqGet_APIVAL() {

   #echo "About API "
   STATUS=`curl -s -X GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   #echo ${STATUS} | jq "."

   #
   # Get Delphix Engine API Version ...
   #
   major=`echo ${STATUS} | jq --raw-output ".result.apiVersion.major"`
   minor=`echo ${STATUS} | jq --raw-output ".result.apiVersion.minor"`
   micro=`echo ${STATUS} | jq --raw-output ".result.apiVersion.micro"`

   let apival=${major}${minor}${micro}
   #echo "Delphix Engine API Version: ${major}${minor}${micro}"

   if [ "$apival" == "" ]
   then
      echo "Error: Delphix Engine API Version Value Unknown $apival, exiting ..."
      exit 1;
   #else
   #   echo "Delphix Engine API Version: ${major}${minor}${micro}"
   fi
   echo $apival
}

#########################################################
## Job Status ...

jqJobStatus () {

JOB=${1}
if [ "${JOB}" != "" ]
then

   #########################################################
   ## Job Information ...

   JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   RESULTS=$( jqParse "${JOB_STATUS}" "status" )
   #echo "json> $JOB_STATUS"

   #########################################################
   ## Get Job State from Results, loop until not RUNNING  ...

   JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
   PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
   echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
   while [ "${JOBSTATE}" == "RUNNING" ]
   do
      sleep ${DELAYTIMESEC}
      JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
      JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
      PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
      echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
   done

   #########################################################
   ##  Producing final status ...

   if [ "${JOBSTATE}" != "COMPLETED" ]
   then
      echo "Error: Delphix Job Did not Complete, please check GUI ${JOB_STATUS}"
      # exit 1
   else
      echo "Job: ${JOB} ${JOBSTATE} ${PERCENTCOMPLETE}% Completed ..."
   fi

else

   echo "Job Number Missing: ${JOB}"

fi     # end if $JOB

}

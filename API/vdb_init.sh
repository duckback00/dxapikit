#!/bin/bash
#v1.1
#
# Delphix Doc's Reference: 
#    https://docs.delphix.com/pages/viewpage.action?pageId=51970750
#
#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################
## Parameter Initialization ...

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
# Authentication ...
#

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
#
# Command Line Arguments ...
#
# $1 = start | stop | disable | enable | status | delete

ACTION=$1
if [[ "${ACTION}" == "" ]] 
then
   echo "Usage: ./vdb_init.sh [start | stop | enable | disable | status | delete] [VDB_Name] "
   echo "---------------------------------"
   echo "start stop enable disable status delete"
   echo "Please Enter Init Option : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
   ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
fi


#########################################################
## Get database container

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "results> $RESULTS"

SOURCE_SID="$2"
if [[ "${SOURCE_SID}" == "" ]]
then

   VDB_NAMES=`echo "${STATUS}" | jq --raw-output '.result[] | .name '`
   echo "---------------------------------"
   echo "VDB Names: [copy-n-paste]"
   echo "${VDB_NAMES}"
   echo " "

   echo "Please Enter dSource or VDB Name (case sensitive): "
   read SOURCE_SID
   if [ "${SOURCE_SID}" == "" ]
   then
      echo "No dSource or VDB Name Provided, Exiting ..."
      exit 1;
   fi
fi;
export SOURCE_SID

#
# Parse out container reference for name of $SOURCE_SID ...
#
CONTAINER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_SID}"'") | .reference '`
echo "database container reference: ${CONTAINER_REFERENCE}"
if [[ "${CONTAINER_REFERENCE}" == "" ]]
then
   echo "Error: No container found for ${SOURCE_SID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1;
fi

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
   #echo ${STATUS} | jq '.'
   #
   # Parse and Display Results ...
   #
   r=`echo ${STATUS} | jq '.result.runtime.status'`
   r1=`echo ${STATUS} | jq '.result.enabled'`
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

   #########################################################
   #
   # Job Information ...
   #
   JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
   RESULTS=$( jqParse "${JOB_STATUS}" "status" )
   #echo "json> $JOB_STATUS"

   #########################################################
   #
   # Get Job State from Results, loop until not RUNNING  ...
   #
   JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
   PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
   echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
   while [ "${JOBSTATE}" == "RUNNING" ]
   do
      echo "Current status as of" $(date) ": ${JOBSTATE} ${PERCENTCOMPLETE}% Completed"
      sleep ${DELAYTIMESEC}
      JOB_STATUS=`curl -s -X GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
      JOBSTATE=$( jqParse "${JOB_STATUS}" "result.jobState" )
      PERCENTCOMPLETE=$( jqParse "${JOB_STATUS}" "result.percentComplete" )
   done

   #########################################################
   ##  Producing final status

   if [ "${JOBSTATE}" != "COMPLETED" ]
   then
      echo "Error: Delphix Job Did not Complete, please check GUI ${JOB_STATUS}"
   #   exit 1
   else
      echo "Job: ${JOB} ${JOBSTATE} ${PERCENTCOMPLETE}% Completed ..."
   fi


fi     # end if $status

############## E O F ####################################
echo "Done ..."
echo " "
exit 0;


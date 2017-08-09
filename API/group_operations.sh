#!/bin/bash
#v1.1
#
# Sample script to create or delete a Delphix Engine Group object ... 
#
#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Command Line Arguments ...
#

ACTION=$1
if [[ "${ACTION}" == "" ]]
then
   echo "Usage: ./group_operations.sh [create | delete] [GROUP_Name] "
   echo "Please Enter Group Option : "
   read ACTION
   if [ "${ACTION}" == "" ]
   then
      echo "No Operation Provided, Exiting ..."
      exit 1;
   fi
   ACTION=$(echo "${ACTION}" | tr '[:upper:]' '[:lower:]')
fi

DELPHIX_GRP="$2"
if [[ "${DELPHIX_GRP}" == "" ]]
then
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
## Get group reference

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


#!/bin/bash
#v1.x

#########################################################
## Subroutines ...

source ./jqJSON_subroutines.sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

#########################################################
#Parameter Initialization

. ./delphix_engine.conf

#
# Required for user timeout ...
#
DE_USER="delphix_admin"          # Delphix Engine User
DE_TIMEOUT=150                   # Timeout integer in minutes

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

echo "Authenticating on ${BaseURL}"

#########################################################
## Session and Login ...

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [ "${RESULTS}" != "OK" ]
then
   echo "Error: Exiting ..."
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get or Create Group 

STATUS=`curl -s -X GET -k ${BaseURL}/user -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

#
# Parse out group reference for name ${SOURCE_GRP} ...
#
USER_REFERENCE=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${DE_USER}"'") | .reference '`
echo "user reference: ${USER_REFERENCE}"

#########################################################
## Update User Session Timeout ...

echo "Update ${DE_USER} session timeout value to ${DE_TIMEOUT} minutes ..."
STATUS=`curl -s -X POST -k --data @- $BaseURL/user/${USER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "User",
    "sessionTimeout": ${DE_TIMEOUT}
}
EOF
`

echo "Returned JSON: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )
echo "Results: ${RESULTS}"


############## E O F ####################################
echo " "
echo "Done ..."
echo " "
exit 0


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
# Required for Database Link and Sync ...
#

SOURCE_SID="Vdelphixdb"             # Virtual Environment Database SID

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
## ...


#########################################################
## Get source

STATUS=`curl -s -X GET -k ${BaseURL}/source -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "Source Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

SOURCE_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.runtime.type=="MSSqlSourceRuntime" and .name=="'"${SOURCE_SID}"'") | .reference '`
echo "source reference: ${SOURCE_REF}"


#echo ${STATUS} | jq "."

echo " " 
echo "preScript: "
echo ${STATUS} | jq --raw-output '.result[] | select(.runtime.type=="MSSqlSourceRuntime" and .name=="'"${SOURCE_SID}"'") | .preScript'

echo " "
echo "postScript: "
echo ${STATUS} | jq --raw-output '.result[] | select(.runtime.type=="MSSqlSourceRuntime" and .name=="'"${SOURCE_SID}"'") | .postScript'

echo " "
echo "operations: "
echo ${STATUS} | jq --raw-output '.result[] | select(.runtime.type=="MSSqlSourceRuntime" and .name=="'"${SOURCE_SID}"'") | .operations '


# 
# Show Pretty (Human Readable) Output ...
#
#echo ${STATUS} | jq "."

# 
# The End is Hear ...
#
echo " "
echo "Done "
exit 0;


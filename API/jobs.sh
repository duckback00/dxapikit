#!/bin/sh

#########################################################
#                   DELPHIX CORP                        #
#########################################################

. ./delphix_engine.conf

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#
# Session ...
#
echo "Session API "
curl -s -X POST -k --data @- ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 7,
        "micro": 0
    }
}
EOF



#
# Login ...
#
echo " "
echo "Login API "
curl -s -X POST -k --data @- ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
  "type": "LoginRequest",
  "username": "${DMUSER}",
  "password": "${DMPASS}"
}
EOF



# curl -s -X GET -k ${BaseURL}/job?toDate=2017-04-01T01:43:24.246Z&pageSize=1000 -b "${COOKIE}" -H "${CONTENT_TYPE}"
# need dash and period - . too

TDT="2017-04-01T01:43:24.246Z"
TDT=$(sed -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\&/%26/g' -e 's/'\''/%28/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/{/%7B/g' -e 's/}/%7D/g' -e 's/:/%3A/g' -e 's/\//%2F/g'<<<$TDT);

echo $TDT

echo " "
echo "Job API "
#STATUS=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT}&pageSize=10 -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#STATUS=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
STATUS=`curl -s -X GET -k ${BaseURL}/job?pageSize=1000 -b "${COOKIE}" -H "${CONTENT_TYPE}"`


echo "STATUS> ${STATUS}" 

#curl -s -X GET -k ${BaseURL}/job?toDate=2017-04-01T01%3A43%3A24.246Z -b "${COOKIE}" -H "${CONTENT_TYPE}"
TMP=`curl -s -X GET -k ${BaseURL}/job?toDate=${TDT} -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#echo "TMP> ${TMP}"


# 
# Show Pretty (Human Readable) Output ...
#
#echo ${STATUS} | jq "."


#################################################################################
# 
# Some jq parsing examples ...
#

#ACTION="DB_LINK"
#echo "${ACTION}"
#echo "${STATUS}" | jq --raw-output '.result[] | select(.actionType=="'"${ACTION}"'") '

ACTION="DB_PROVISION"
echo "${ACTION}"
echo "${STATUS}" | jq --raw-output '.result[] | select(.actionType=="'"${ACTION}"'") '

# 
# The End is Hear ...
#
echo " "
echo "Done "
exit 0;


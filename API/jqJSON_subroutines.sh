

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
        "minor": 7,
        "micro": 0
    }
}
EOF
`

   #echo "Session: ${STATUS}"
   RESULTS=$( jqParse "${STATUS}" "status" )

   STATUS=`curl -s -X POST -k --data @- $BaseURL/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
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



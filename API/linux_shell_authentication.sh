
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


#Returned to the command line are the results (added linefeeds for readability)
#{
#  "type":"OKResult",
#  "status":"OK",
#  "result":{
#    "type":"APISession",
#    "version":{
#      "type":"APIVersion",
#      "major":1,
#      "minor":7,
#      "micro":0
#    },
#    "locale":null
#    ,"client":null
#  }
#  ,"job":null
#  ,"action":null
#}

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


#Returned to the command line are the results (added linefeeds for readability)
#{
#  "status":"OK",
#  "result":"USER-2",
#  "job":null,
#  "action":null
#}


#
# Get Environment ...
#
echo " "
echo "Environment API "
curl -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"

#Returned to the command line are the results (added linefeeds for readability) 
#{
#"type":"ListResult",
#"status":"OK",
#"result":
#[
# {"type":"WindowsHostEnvironment",
#  "reference":"WINDOWS_HOST_ENVIRONMENT1",
#  "namespace":null,
#  "name":"Window Target",
#  "description":"",
#  "primaryUser":"HOST_USER-1",
#  "enabled":false,
#  "host":"WINDOWS_HOST1",
#  "proxy":null
# },
# {
#  "type":"UnixHostEnvironment",
#  "reference":"UNIX_HOST_ENVIRONMENT-3",
#  "namespace":null,
#  "name":"Oracle Target",
#  "description":"",
#  "primaryUser":"HOST_USER-3",
#  "enabled":true,
#  "host":"UNIX_HOST-3","aseHostEnvironmentParameters":null
# }
#],
#"job":null,
#"action":null,
#"total":2,
#"overflow":false
#}

echo " "
echo "Done "
exit 0;


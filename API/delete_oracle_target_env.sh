
. ./delphix_engine.conf

# STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`


curl -s -X POST -k --data @- ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 5,
        "micro": 3
    }
}
EOF

echo "" 
curl -s -X POST -k --data @- ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LoginRequest",
    "username": "${DMUSER}",
    "password": "${DMPASS}"
}
EOF

echo ""
curl -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}" 


echo ""
curl -X POST -k --data @- ${BaseURL}/environment/UNIX_HOST_ENVIRONMENT-11/delete -b "${COOKIE}" -H "${CONTENT_TYPE}"  <<EOF
{
}
EOF

echo ""


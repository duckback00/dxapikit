
. ./delphix_engine.conf

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


curl -s -X POST -k --data @- ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "LoginRequest",
    "username": "${DMUSER}",
    "password": "${DMPASS}"
}
EOF


curl -X POST -k --data @- ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
{
    "type": "HostEnvironmentCreateParameters",
    "primaryUser": {
        "type": "EnvironmentUser",
        "name": "DELPHIX\\\delphix_admin",
        "credential": {
            "type": "PasswordCredential",
            "password": "delphix"
        }
    },
    "hostEnvironment": {
        "type": "WindowsHostEnvironment",
        "name": "Window Target"
    },
    "hostParameters": {
        "type": "WindowsHostCreateParameters",
        "host": {
            "type": "WindowsHost",
            "address": "172.16.160.142",
            "connectorPort": 9100
        }
    }
}
EOF





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
        "name": "delphix",
        "credential": {
            "type": "PasswordCredential",
            "password": "delphix"
        }
    },
    "hostEnvironment": {
        "type": "UnixHostEnvironment",
        "name": "Oracle Target"
    },
    "hostParameters": {
        "type": "UnixHostCreateParameters",
        "host": {
            "type": "UnixHost",
            "address": "172.16.160.133",
            "toolkitPath": "/var/opt/delphix/toolkit"
        }
    }
}
EOF




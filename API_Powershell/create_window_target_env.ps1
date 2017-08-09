# Filename: create_window_target_env.ps1
# Description: Delphix Powershell Sample Authentication Script ...
# Date: 2016-08-02
# Author: Bitt...
#

#
# Variables ...
#
$nl = [Environment]::NewLine
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$cookie = "cookies.txt"

# 
# Session JSON Data ...
#
write-output "${nl}Creating session.json file ..."
$json = @"
{
    "type": "APISession",
    "version": {
        "type": "APIVersion",
        "major": 1,
        "minor": 7,
        "micro": 0
    }
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "session.json" -encoding utf8

#
# Delphix Curl Session API ...
#
write-output "${nl}Calling Session API ...${nl}"
$results = (curl --insecure -c "${cookie}" -sX POST -H "Content-Type: application/json" -d "@session.json" -k ${BaseURL}/session)
write-output "Session API Results: ${results}"

#
# Login JSON Data ...
# 
write-output "${nl}Creating login.json file ..."
$user = "delphix_admin"
$pass = "delphix"
$json = @"
{
    "type": "LoginRequest",
    "username": "${user}",
    "password": "${pass}"
}
"@

#
# Output File using UTF8 encoding ...
#
write-output $json | Out-File "login.json" -encoding utf8

#
# Delphix Curl Login API ...
#
write-output "${nl}Calling Login API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "@login.json" -k ${BaseURL}/login)
write-output "Login API Results: ${results}"


#######################################################################
#
# Create Delphix Environment ...
#
$json = @"
{
    "type": "HostEnvironmentCreateParameters",
    "primaryUser": {
        "type": "EnvironmentUser",
        "name": "DELPHIX\\delphix_admin",
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
            "address": "172.16.160.183",
            "connectorPort": 9100
        }
    }
}
"@

write-output $json | Out-File "create_env.json" -encoding utf8

write-output "${nl}Calling Create Environment API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "@create_env.json" -k ${BaseURL}/environment)
write-output "Environment API Results: ${results}"

#curl -X POST -k --data @- http://172.16.160.195/resources/json/delphix/environment \
#    -b ~/cookies.txt -H "Content-Type: application/json" <<EOF




#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;

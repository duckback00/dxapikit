# Filename: auth.ps1
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

#
# Delphix Curl system API ...
#
write-output "${nl}Calling System API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX GET -H "Content-Type: application/json" -k ${BaseURL}/system)
write-output "System API Results: ${results}"

#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;

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
$user = "delphix_admin"
$pass = "delphix"

# 
# Session JSON Data ...
#
$json = @"
{
    \"type\": \"APISession\",
    \"version\": {
        \"type\": \"APIVersion\",
        \"major\": 1,
        \"minor\": 7,
        \"micro\": 0
    }
}
"@


#
# Delphix Curl Session API ...
#
write-output "${nl}Calling Session API ...${nl}"
$results = (curl --insecure -c "${cookie}" -sX POST -H "Content-Type: application/json" -d "${json}" -k ${BaseURL}/session)
write-output "Session API Results: ${results}"

#
# Login JSON Data ...
# 
$json = @"
{
    \"type\": \"LoginRequest\",
    \"username\": \"${user}\",
    \"password\": \"${pass}\"
}
"@


#
# Delphix Curl Login API ...
#
write-output "${nl}Calling Login API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "${json}" -k ${BaseURL}/login)
write-output "Login API Results: ${results}"

#######################################################################
#
# Create Delphix Environment ...
#
$json = @"
{
    \"type\": \"HostEnvironmentCreateParameters\",
    \"primaryUser\": {
        \"type\": \"EnvironmentUser\",
        \"name\": \"DELPHIX\\delphix_admin\",
        \"credential\": {
            \"type\": \"PasswordCredential\",
            \"password\": \"delphix\"
        }
    },
    \"hostEnvironment\": {
        \"type\": \"WindowsHostEnvironment\",
        \"name\": \"Windows Target\"
    },
    \"hostParameters\": {
        \"type\": \"WindowsHostCreateParameters\",
        \"host\": {
            \"type\": \"WindowsHost\",
            \"address\": \"172.16.160.196\",
            \"connectorPort\": 9100
        }
    }
}
"@


write-output "${nl}Calling Create Environment API ...${nl}"
$results = (curl --insecure -b "${cookie}" -sX POST -H "Content-Type: application/json" -d "${json}" -k ${BaseURL}/environment)
write-output "Environment API Results: ${results}"

#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;

#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2017 by Delphix. All rights reserved.
#
# Program Name : auth1.ps1
# Description  : Delphix PowerShell API Basic Example  
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable
#  2.) Change values below as required
#
# Usage: . .\auth1.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Delphix Engine Variables ...
#
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$DMUSER = "delphix_admin"
$DMPASS = "delphix"

#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

# 
# Application Variables ...
#
$nl = [Environment]::NewLine
$CONTENT_TYPE="Content-Type: application/json"
$COOKIE = "cookies.txt"

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

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

#write-output "${nl}${json}${nl}"

#########################################################
## Delphix Curl Session API ...

write-output "${nl}Calling Session API ...${nl}"
$results = (curl.exe -sX POST -k ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
write-output "Session API Results: ${results}"

#########################################################
## Login JSON Data ... 

$json = @"
{
    \"type\": \"LoginRequest\",
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@

#########################################################
## Delphix Curl Login API ...

write-output "${nl}Calling Login API ...${nl}"
$results = (curl.exe -sX POST -k ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
write-output "Login API Results: ${results}"

#########################################################
## Delphix Curl system API ...

write-output "${nl}Calling System API ...${nl}"
$results = (curl.exe -sX GET -k ${BaseURL}/system -b "${COOKIE}" -H "${CONTENT_TYPE}")
write-output "System API Results: ${results}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable DMUSER, DMPASS, BaseURL, COOKIE, CONTENT_TYPE, results, json
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

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
# Program Name : auth.ps1
# Description  : Delphix PowerShell API Basic Example  
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Change values below as required
#
# Usage: ./auth.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################


#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

#
# Variables ...
#
$nl = [Environment]::NewLine
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$content_type="Content-Type: application/json"
$cookie = "cookies.txt"
$user = "delphix_admin"
$pass = "delphix"

# 
# Session JSON Data ...
#
write-output "${nl}Creating session.json file ..."
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

write-output "${nl}${json}${nl}"

#
# Delphix Curl Session API ...
#
write-output "${nl}Calling Session API ...${nl}"
$results = (curl --insecure -sX POST -k ${BaseURL}/session -c "${cookie}" -H "${content_type}" -d "${json}")

write-output "Session API Results: ${results}"

#
# Login JSON Data ...
# 
write-output "${nl}Creating login.json file ..."
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
$results = (curl --insecure -sX POST -k ${BaseURL}/login -b "${cookie}" -H "${content_type}" -d "${json}")
write-output "Login API Results: ${results}"

#
# Delphix Curl system API ...
#
write-output "${nl}Calling System API ...${nl}"
$results = (curl --insecure -sX GET -k ${BaseURL}/system -b "${cookie}" -H "${content_type}")
write-output "System API Results: ${results}"

#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;

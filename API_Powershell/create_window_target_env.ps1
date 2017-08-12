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
# Program Name : create_windows_target_env.ps1
# Description  : Delphix PowerShell API Create Env Example  
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: ./create_windows_target_env.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#
# Variables ...
#
$nl = [Environment]::NewLine
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$cookie = "cookies.txt"
$user = "delphix_admin"
$pass = "delphix"
$host_name = "172.16.160.196"         # IP Address or Fully Qualified Hostname
$host_user = "DELPHIX\\delphix_admin"
$host_pass = "delphix"
$TARGET_ENV = "Windows Target"

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
        \"name\": \"${host_user}\",
        \"credential\": {
            \"type\": \"PasswordCredential\",
            \"password\": \"${host_pass}\"
        }
    },
    \"hostEnvironment\": {
        \"type\": \"WindowsHostEnvironment\",
        \"name\": \"${TARGET_ENV}\"
    },
    \"hostParameters\": {
        \"type\": \"WindowsHostCreateParameters\",
        \"host\": {
            \"type\": \"WindowsHost\",
            \"address\": \"${host_name}\",
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

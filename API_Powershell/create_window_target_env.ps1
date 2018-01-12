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
# Created      : 2017-11-15
# Version      : v1.1
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: . .\create_windows_target_env.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Application Variables ...
#
$host_name = "172.16.160.134"            # IP Address or Fully Qualified Hostname
$host_user = "DELPHIX\\DELPHIX_ADMIN"
$host_pass = "delphix"
$TARGET_ENV = "Windows Host"

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Local Functions ...

. .\delphixFunctions.ps1

#########################################################
## Authentication ...

Write-Output "Authenticating on ${BaseURL} ..."
$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
Write-Output "Login Results: ${results}"

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

Write-Output "JSON: $json"

Write-Output "Calling Create Environment API ..."
$results = (curl.exe -sX POST -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
Write-Output "Environment API Results: ${results}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

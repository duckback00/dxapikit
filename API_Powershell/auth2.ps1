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
# Program Name : auth2.ps1
# Description  : Delphix PowerShell API Basic Example  
# Author       : Alan Bitterman
# Created      : 2017-11-10
# Version      : v1.2
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: . .\auth2.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Local Functions ...

. .\delphixFunctions.ps1

#########################################################
## Authentication ...

Write-Output "Authenticating on ${BaseURL} ... ${nl}"
$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
Write-Output "Login Results: ${results}"

#########################################################
## Delphix Curl system API ...

Write-Output "${nl}Calling System API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/system -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"    
Write-Output "System API Results: ${results}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
#Remove-Variable DMUSER, DMPASS, BaseURL, COOKIE, CONTENT_TYPE, DELAYTIMESEC, DT, results, status
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

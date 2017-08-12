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
# Program Name : delphixFunctions.ps1
# Description  : Delphix PowerShell API Functions  
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: . ./delphixFunctions.ps1
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

Function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}

Function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}

Function RestSession([string]$DMUSER, [string]$DMPASS, [string]$BaseURL, [string]$COOKIE, [string]$CONTENT_TYPE){
   $nl = [Environment]::NewLine
   #write-output "${nl} Parameters: $DMUSER $DMPASS $COOKIE ${nl}"
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
   #
   # Delphix Curl Session API ... 
   #
   #write-output "${nl}Calling Session API ...${nl}"
   $results = (curl --insecure -sX POST -k ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
   #write-output "Session API Results: ${results}"  
   # 
   # Login JSON Data ...
   #
   $json = @"
{
    \"type\": \"LoginRequest\",
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@
   #write-output "${nl}${json}${nl}"
   #
   # Delphix Curl Login API ...
   #
   #write-output "${nl}Calling Login API ...${nl}"
   $results = (curl --insecure -sX POST -k ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
   #write-output "${nl}Login API Results: ${results}"

   return [string]$results
}

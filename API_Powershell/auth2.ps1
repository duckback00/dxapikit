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
# Created      : 2017-08-10
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: ./auth2.ps1
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Local Functions ...

. .\delphixFunctions.ps1

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#########################################################
## Authentication ...

write-output "Authenticating on ${BaseURL} ... ${nl}"

$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
#write-output "${nl} Results are ${results} ..."

$o = ConvertFrom-Json20 $results
$status=$o.status                       #echo "Status ... $status ${nl}"
if ("${status}" -ne "OK") {
   echo "Job Failed with ${status} Status ${nl} $results ${nl}"
   exit 1
}

#########################################################
#
# Delphix Curl system API ...
#
write-output "${nl}Calling System API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/system -b "${COOKIE}" -H "${CONTENT_TYPE}")
write-output "System API Results: ${results}"

#
# The End is Near ...
#
echo "${nl}Done ...${nl}"
exit;

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
# Program Name : delete_database_sqlserver.ps1
# Description  : Delphix PowerShell API Delete SQLServer Database 
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Change values below as required
#
# Usage: 
# . .\delete_database_sqlserver.ps1 [dSource_or_VDB_name]
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
# Parameter Initialization

##
## Defaults ... Get from Command Line or use the default identified ...
##
param (
    [string]$SOURCE_SID = ""
)

if ("${SOURCE_SID}" -eq "") {
   Write-Output "Error, missing dSource or VDB Name ${SOURCE_SID}, Exiting ... ${nl}"
   exit 1
}

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
#Write-Output "${nl} Results are ${results} ..."

Write-Output "Login Successful ..."

#########################################################
## Get database container ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer"} | Select-Object
$CONTAINER_REFERENCE=$b.reference
Write-Output "container reference: ${CONTAINER_REFERENCE}"

#########################################################
## Delete VDB ...

$json = @"
{
    \"type\": \"DeleteParameters\"
}
"@


Write-Output "Deleting dSource or VDB Name ${SOURCE_SID} ..."
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/${CONTAINER_REFERENCE}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "database delete job results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$JOB=$o.job
Write-Output "Job # $JOB ${nl}"

# 
# Allow job to submit internally before while loop ...
#
sleep 1

Monitor_JOB "$BaseURL" "$COOKIE" "$CONTENT_TYPE" "$JOB"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

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
# Program Name : vdb_operations.ps1
# Description  : Delphix PowerShell API provision VDB Example  
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage:
#  . .\vdb_operations.ps1
# 
# Non-Interactive Usage:
# . .\vdb_operations.ps1 [sync|refresh|rollback] [VDB_Name]
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Get Command Line Arguements ...
## (must be first thing in file)

param (
    [string]$ACTION = "",
    [string]$SOURCE_SID = ""
)

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
## Command Line Arguements Processing ...

$arrA = "sync","refresh","rollback"
if ("${ACTION}" -eq "" ) {
   Write-Output "Usage: . .\vdb_operations [$arrA] [VDB_Name]"
   Write-Output "------------------------------"
   Write-Output "$arrA"
   $ACTION = Read-Host -Prompt "Please Enter Operation"
   if ("${ACTION}" -eq "" ) { 
      Write-Output "No Operation Provided, Exiting ..."
      exit 1
   }
}
$ACTION=${ACTION}.ToLower()

#########################################################
## verify argument passed to the script

switch (${ACTION}) { 
   {$arrA -eq $_} {
      Write-Output "Action: ${ACTION}"
   } 
   default {
      Write-Output "Unknown option: ${ACTION}"
      Write-Output "Valid Options are [ $arrA ]" 
      Write-Output "Exiting ..."
      exit 1
   }
}

#########################################################
## Get database container ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result

if ("${SOURCE_SID}" -eq "") {
   Write-Output "--------------------------------------"
   Write-Output "VDB Names: [copy-n-paste]"
   $a.name
   $SOURCE_SID = Read-Host -Prompt "Please Enter dSource of VDB Name (case sensitive)"
   if ("${SOURCE_SID}" -eq "" ) { 
      Write-Output "No dSource or VDB Provided, Exiting ..."
      exit 1
   }
}

#
# Parse (Cont) ...
#
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer"} | Select-Object
$CONTAINER_REFERENCE=$b.reference
Write-Output "container reference: ${CONTAINER_REFERENCE}"

if ("${CONTAINER_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No container found for ${SOURCE_ID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## Get provision source database container reference ...

#Write-Output "${nl}Calling database parent API ...${nl}"
$results = (curl.exe -sX GET -k ${BaseURL}/database/${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.reference -eq "${CONTAINER_REFERENCE}" } | Select-Object
$PARENT_REFERENCE=$b.provisionContainer
Write-Output "parent reference: ${PARENT_REFERENCE}"

#########################################################
## operations ...

# "v190" Options
#
# if (${apival} -gt 190) { }
#
#   \"type\": \"MSSqlExistingMostRecentBackupSyncParameters\"

#      $json = @"
#{
#   \"type\": \"MSSqlNewCopyOnlyFullBackupSyncParameters\"
#  ,\"compressionEnabled\": false
#}
#"@

#   \"type\": \"MSSqlExistingSpecificBackupSyncParameters\"
#  ,\"backupUUID\": \"______\"

switch (${ACTION}) {
 
  "sync" { 

      $json = @"
{
   \"type\": \"MSSqlSyncParameters\"
}
"@


   }

   "rollback"  { 
      $json = @"
{
    \"type\": \"RollbackParameters\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\",
        \"location\": \"LATEST_POINT\"
    }
}
"@

   }

   "refresh" { 
      $json = @"
{
    \"type\": \"RefreshParameters\",
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${PARENT_REFERENCE}\",
        \"location\": \"LATEST_POINT\"
    }
}
"@

   }

}     # end switch ...

# Write-Output "JSON> $json"

#Write-Output "${nl}Calling database provision API ...${nl}"
$results = (curl.exe -sX POST -k ${BaseURL}/database/${CONTAINER_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "database ${ACTION} API Results: ${results}"

#########################################################
## Job ...

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

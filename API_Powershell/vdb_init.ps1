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
# Program Name : vdb_init.ps1
# Description  : Delphix PowerShell API calls for state of VDBs  
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
#  . .\vdb_init.ps1
# 
# Non-Interactive Usage:
# . .\vdb_init.ps1 [start|stop|enable|disable|status|delete] [VDB_Name]
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

$arrA = "start","stop","enable","disable","status","delete"
if ("${ACTION}" -eq "" ) {
   Write-Output "Usage: ./vdb_init.sh [$arrA] [VDB_Name] "
   Write-Output "---------------------------------"
   Write-Output "$arrA"
   $ACTION = Read-Host -Prompt "Please Enter Init Option: "
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

# 
# Prompt for dSource or VDB Name ...
#
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
# Parse Results (cont) ...
#
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer"} | Select-Object
$CONTAINER_REFERENCE=$b.reference
Write-Output "container reference: ${CONTAINER_REFERENCE}"

if ("${CONTAINER_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No container found for ${SOURCE_ID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## Get source reference ... 

#Write-Output "${nl}Calling source API ...${nl}"
$results = (curl.exe -sX GET -k ${BaseURL}/source -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Source API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.container -eq "${CONTAINER_REFERENCE}" -and $_.staging -ne "True" } | Select-Object
$VDB=$b.reference
$VENDOR_SOURCE=$b.type
Write-Output "source reference: ${VDB}"
Write-Output "vendor source: ${VENDOR_SOURCE}"

#########################################################
## init ...

#
# Execute VDB init Request ...
#
$r = ""
$r1 = ""
$deleteParameters = ""
$json = ""
$JOB = ""
$JOBSTATE = "" 
$PERCENTCOMPLETE = ""
$d = ""
if ("${ACTION}" -eq "status") {

   # 
   # Get Source Status ...
   #
   $results = (curl.exe -sX GET -k ${BaseURL}/source/${VDB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
   $status = ParseStatus "${results}" "${ignore}"
   #Write-Output "Source API Results: ${results}"

   #
   # Convert Results String to JSON Object and Get Results Status ...
   #
   $o = ConvertFrom-Json $results
   $a = $o.result
   $b = $a.runtime     ### | where { $_.container -eq "${CONTAINER_REFERENCE}" } | Select-Object
   $r=$b.status
   $r1=$b.enabled
   Write-Output "Runtime Status: ${r}"
   Write-Output "Enabled: ${r1}"

} else {

   # 
   # delete ...
   #
   if ( "${ACTION}" -eq "delete" ) {

      if ( ${VENDOR_SOURCE} -contains "Oracle*" ) {
         $deleteParameters="OracleDeleteParameters"
      } else {
         $deleteParameters="DeleteParameters"
      }

      $json = @"
{
    \"type\": \"${deleteParameters}\"
}
"@

      Write-Output "delete parameters type: ${deleteParameters}"
      $results = (curl.exe -sX POST -k ${BaseURL}/database/${CONTAINER_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
      $status = ParseStatus "${results}" "${ignore}"
      Write-Output "Database Delete API Results: ${results}"

   } else {

      # 
      # All other init options; start | stop | enable | disable ...
      #
      # Submit VDB init change request ...
      #
      $results = (curl.exe -sX POST -k ${BaseURL}/source/${VDB}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}")
      $status = ParseStatus "${results}" "${ignore}"
      Write-Output "Source init API Results: ${results}"
   
   }      # end if delete ...

   #########################################################
   ## Job ...

   $o = ConvertFrom-Json $results 
   $JOB=$o.job
   Write-Output "Job # $JOB"

   if ( "${JOB}" -eq "" ) {
      Write-Output "No Job ..."
      exit;
   }
   # 
   # Allow job to submit internally before while loop ...
   #
   sleep 1

   Monitor_JOB "$BaseURL" "$COOKIE" "$CONTENT_TYPE" "$JOB"

}      # end if status

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

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
# Program Name : flows.ps1
# Description  : Delphix API timeflows examples
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: . .\flows.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Get Command Line Arguements ...
## (must be first thing in file)

param (
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

Function human_print([uint64]$B){
   if ( $B -lt 1024 ) { 
      $B=[math]::Round($B,2)
      $hB = "${B} Bytes"
   } else {
      $KB=($B+512)/1024
      $KB=[math]::Round($KB,2)
      if ( $KB -lt 1024 ) {
         $hb = "${KB} KB"
      } else {
         $MB=($KB+512)/1024
         $MB=[math]::Round($MB,2)
         if ( $MB -lt 1024 ) {
            $hb = "${MB} MB"
         } else {
            $GB=($MB+512)/1024
            $GB=[math]::Round($GB,2)
            if ( $GB -lt 1024 ) {
               $hb = "${GB} GB"
            } else {
               $TB=($GB+512)/1024
               $TB=[math]::Round($TB,2)
               if ( $TB -lt 1024 ) {
                  $hb = "${TB} TB"
               } else {
                  $hb = "${B} too big"
               }
            }
         }
      }
   }
   return [string]$hB
}

#human_print(1456946204)

#########################################################
## Authentication ...

Write-Output "Authenticating on ${BaseURL} ... ${nl}"
$results=RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
#Write-Output "${nl} Results are ${results} ..."

Write-Output "Login Successful ..."

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
## List timeflows for the container reference

Write-Output " "
Write-Output "Timeflows API ..."
$results = (curl.exe -sX GET -k ${BaseURL}/timeflow?database=${CONTAINER_REFERENCE} -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result

Write-Output "timeflow names:"
$a.name
Write-Output " "
$FLOW_NAME = Read-Host -Prompt "Select timeflow Name (copy-n-paste from above list)"
if ( "${FLOW_NAME}" -eq "" ) {
   Write-Output "No Flow Name provided, exiting ... ${FLOW_NAME} "
   exit 1;
}

#
# Get timeflow reference ...
#
$b = $a | where { $_.name -eq "${FLOW_NAME}"} | Select-Object
$FLOW_REF=$b.reference
Write-Output "timeflow reference: ${FLOW_REF}"

#########################################################
## timeflowRanges for this timeflow ...

Write-Output " "
Write-Output "TimeflowRanges for this timeflow ... "
$json=@"
{
    \"type\": \"TimeflowRangeParameters\"
}
"@

#Write-Output "JSON: $json"

$results = (curl.exe -sX POST -k ${BaseURL}/timeflow/${FLOW_REF}/timeflowRanges -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"

#Write-Output "Results: ${results}"
$o = ConvertFrom-Json $results
$o.result

sleep 1

#########################################################
## Get snapshot for this timeflow ...

Write-Output " "
Write-Output "Snapshot per Timeflow ... "
$results = (curl.exe -sX GET -k ${BaseURL}/snapshot?timeflow=${FLOW_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"

#Write-Output "RESUTLS: $results"

$o = ConvertFrom-Json $results
$a = $o.result

Write-Output "snapshots:"
$a.name
Write-Output " "
$SYNC_NAME = Read-Host -Prompt "Select snapshot Name (copy-n-paste from above list)"
if ( "${SYNC_NAME}" -eq "" ) {
   Write-Output "No Snapshot Name provided, exiting ... ${SYNC_NAME} "
   exit 1;
}

$b = $a | where { $_.name -eq "${SYNC_NAME}"} | Select-Object
$SYNC_REF=$b.reference
Write-Output "snapshot reference: ${SYNC_REF}"

#
# Display ...
#

Write-Output " "
Write-Output "Snapshot Details for ${SYNC_REF} ... "
$results = (curl.exe -sX GET -k ${BaseURL}/snapshot/${SYNC_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "results: $results"
$o = ConvertFrom-Json $results
$a = $o.result
Write-Output "$a"

#########################################################
## Get snapshot space ...

Write-Output "-----------------------------"
Write-Output "-- Snapshot Space JSON ... "

$json=@"
{
    \"type\": \"SnapshotSpaceParameters\",
    \"objectReferences\": [
        \"${SYNC_REF}\"
   ]
}
"@

Write-Output "JSON: $json"

$SPACE = (curl.exe --insecure -sX POST -k ${BaseURL}/snapshot/space -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$o = ConvertFrom-Json $SPACE
$a = $o.result
Write-Output "results: $a"
$b = $a.totalSize
[uInt64]$s = [convert]::ToUInt64($b) 
$SIZE=human_print(${s})
Write-Output "Snapshot Total Size: ${SIZE}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0;

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
# Program Name : group_operations.ps1
# Description  : Delphix API for groups
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.1 2017-08-14
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: 
# . .\group_operations.ps1
#
# Non-Interactive Usage: 
# . .\group_operations.ps1 [create | delete] [Group_Name]
#
# Sample script to create or delete a Delphix Engine Group object ... 
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
    [string]$DELPHIX_GRP = ""
)

#
# For non-interactive defaults ...
# 
# $DEF_ACTION="create"
# $DEF_DELPHIX_GRP="delme2"
#
# For full interactive option, set default values to nothing ...
#
$DEF_ACTION=""
$DEF_DELPHIX_GRP=""

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
## Get List of Existing Group Names ...

#Write-Output "${nl}Calling Group API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result

#########################################################
## Command Line Arguments ...

$arrA = "create","delete"
if ("${ACTION}" -eq "" ) {
   if ( "${DEF_ACTION}" -eq "" ) {
      Write-Output "Usage: . .\group_operations [$arrA] [VDB_Name]"
      Write-Output "------------------------------"
      Write-Output "Valid Operations:"
      Write-Output "$arrA"
      $ACTION = Read-Host -Prompt "Please Enter Operation"
      if ("${ACTION}" -eq "" ) { 
         Write-Output "No Operation Provided, Exiting ..."
         exit 1
      }
   } else {
      echo "No Action Provided, using Default ..."
      $ACTION=${DEF_ACTION}
   } 
}
$ACTION=${ACTION}.ToLower()

switch (${ACTION}) { 
   {$arrA -eq $_} {
      Write-Output "Action: ${ACTION}"
   } 
   default {
      Write-Output "------------------------------"
      Write-Output "Unknown option: ${ACTION}"
      Write-Output "Valid Options are [ $arrA ]" 
      Write-Output "Exiting ..."
      exit 1
   }
}

if ( "${DELPHIX_GRP}" -eq "" ) {
   if ( "${DEF_DELPHIX_GRP}" -eq "" ) {
      #
      # Parse out group names ...
      #
      Write-Output "------------------------------"
      Write-Output "Existing Group Names: "
      $a.name
      $DELPHIX_GRP = Read-Host -Prompt "Please Enter Group Name (case sensitive)"
      if ( "${DELPHIX_GRP}" -eq "" ) {
          Write-Output "No Group Name Provided, Exiting ..."
          exit 1;
      }
   } else {
      echo "No Group Provided, using Default ..."
      $DELPHIX_GRP=${DEF_DELPHIX_GRP}
   } 
 }

#########################################################
## Get Group Reference ...

#
# Parse out container reference for name of $DELPHIX_GRP ...
#
$b = $a | where { $_.name -eq "${DELPHIX_GRP}" -and $_.type -eq "Group"} | Select-Object
$GROUP_REFERENCE=$b.reference
Write-Output "group reference: ${GROUP_REFERENCE}"

#########################################################
## create or delete the group based on the argument passed to the script

switch (${ACTION}) {
 
   "create" { 

      if ( "${ACTION}" -eq "create" -and "${GROUP_REFERENCE}" -eq "" ) {
         # 
         # Create Group ...
         #
         # Write-Output "Create Group ..."

         $json = @"
{
   \"type\": \"Group\"
  ,\"name\": \"${DELPHIX_GRP}\"
}
"@

         #Write-Output "${nl}Create Group API ...${nl}"
         $results = (curl.exe -sX POST -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
         $status = ParseStatus "${results}" "${ignore}"
         Write-Output "group ${ACTION} API Results: ${results}"

         #
         # Convert Results String to JSON Object and Get Results Status ...
         #
         $o = ConvertFrom-Json $results
         $a=$o.result
         Write-Output "${ACTION}d group ""${DELPHIX_GRP}"" with reference: $a ${nl}"
           
      } else {
         Write-Output "ERROR: Unable to create group ""${DELPHIX_GRP}"" since it already exists ..."
      } 

   }
   "delete" {

      # 
      # delete ...
      #
      #Write-Output "Delete Group ..."

      if ( "${ACTION}" -eq "delete" -and "${GROUP_REFERENCE}" -ne "" ) {

         $json=@"
{}
"@

         #Write-Output "${nl}Delete Group API ...${nl}"
         $results = (curl.exe -sX POST -k ${BaseURL}/group/${GROUP_REFERENCE}/${ACTION} -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
         $status = ParseStatus "${results}" "${ignore}"
         Write-Output "group ""${DELPHIX_GRP}"" ${ACTION}d"
         #Write-Output "API Results: ${results}"
           
      } else {
         Write-Output "ERROR: Unable to delete group name ""${DELPHIX_GRP}"" does not exist ..."
      } 


   }    # end delete
   default {
      Write-Output "Unknown option: ${ACTION}"
      Write-Output "Valid Options are [ $arrA ]" 
      Write-Output "Exiting ..."
      exit 1
   }

}      # end switch 

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

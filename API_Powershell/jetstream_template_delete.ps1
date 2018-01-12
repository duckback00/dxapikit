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
# Program Name : jetstream_template_delete.ps1 
# Description  : Delphix API to delete a JetStream Template
# Author       : Alan Bitterman
# Created      : 2017-11-15
# Version      : v1.0
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: 
# . .\jetstream_template_delete.ps1
#
# Non-interactive Usage:
# . .\jetstream_template_delete.ps1 [template_name]  Action 
# . .\jetstream_template_delete.ps1 [template_name] [delete]
#
# . .\jetstream_template_delete.ps1 tpl delete 
# . .\jetstream_template_delete.ps1 tpl 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Get Command Line Arguements ...
## (must be first thing in file)

param (
    [string]$JS_TEMPLATE = "",
    [string]$ACTION = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
# 
# $DEF_JS_TEMPLATE="tpl2"
# $DEF_ACTION="delete"
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""
$DEF_ACTION=""

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
## Get Template Reference ...

#Write-Output "${nl}Calling Jetstream Template API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${JS_TEMPLATE}" -and $_.type -eq "JSDataTemplate"} | Select-Object
$JS_TPL_CHK=$b.name
#Write-Output "$JS_TEMPLATE ... chk ... $JS_TPL_CHK"

if ( "${JS_TPL_CHK}" -eq ""  -or "${JS_TEMPLATE}" -eq "" ) {    
   if ( "${JS_TPL_CHK}" -ne "" ) {
      Write-Output "Template Name ${JS_TEMPLATE} Already Exists, Please try again ..."
   }
   $ZTMP="New Template Name"
   if ( "${DEF_JS_TEMPLATE}" -eq "" ) {
      Write-Output "Existing Template Names: "
      $a.name
      Write-Output "---------------------------------"
      $JS_TEMPLATE = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_TEMPLATE}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $JS_TEMPLATE=${DEF_JS_TEMPLATE}
   }
}

Write-Output "Template Name: ${JS_TEMPLATE}"

$b = $a | where { $_.name -eq "${JS_TEMPLATE}" -and $_.type -eq "JSDataTemplate"} | Select-Object
$JS_TPL_REF=$b.reference 
Write-Output "template reference: ${JS_TPL_REF}"

if ( "${JS_TPL_REF}" -eq "" ) {
   Write-Output "${ZTMP} Reference ${JS_TPL_REF} for ${JS_TEMPLATE} not found, Exiting ..."
   exit 1;
}


#########################################################
## Command Line Arguments ...

$arrA = "delete"
if ("${ACTION}" -eq "" ) {
   if ( "${DEF_ACTION}" -eq "" ) {
      Write-Output "------------------------------"
      Write-Output "Valid Operations:"
      Write-Output "$arrA"
      $ACTION = Read-Host -Prompt "Please Enter Operation"
      if ("${ACTION}" -eq "" ) { 
         Write-Output "No Operation Provided, Exiting ..."
         exit 1
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
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

#########################################################
## Delete Template ...

$json=@"
{}
"@

# Write-Output "${nl}Delete Template API ...${nl}"
$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/template/${JS_TPL_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "${ACTION} template API Results: ${results}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " " 
Write-Output "Done ... (no job required for this action)"
Write-Output " "
exit 0

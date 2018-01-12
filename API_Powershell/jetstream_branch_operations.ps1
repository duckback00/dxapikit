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
# Program Name : jetstream_branch_operations.ps1
# Description  : Delphix API to list, activate or delete Container Branches
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
# ./jetstream_branch_operations.ps1
#
# ... or ...
#
# Non-Interactive Usage:
# ./jetstream_branch_operations.ps1 [template_name] [container_name] [branch_name] [list|activate|delete]
#
# ./jetstream_branch_operations.ps1 tpl cdc default list
# ./jetstream_branch_operations.ps1 tpl cdc default activate
# ./jetstream_branch_operations.ps1 tpl cdc branch_break_fix delete
# 
# ./jetstream_branch_operations.ps1 tpl cdc
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
    [string]$JS_CONTAINER_NAME = "",
    [string]$JS_BRANCH_NAME = "",
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
# $DEF_JS_TEMPLATE="tpl"           # Jetstream Template Name
# $DEF_JS_CONTAINER_NAME="dc"      # Jetstream Container Name
# $DEF_JS_BRANCH_NAME="default"    # Jetstream Branch Name
# $DEF_ACTION="list"		 # Action [list|activate|delete]
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""
$DEF_JS_CONTAINER_NAME=""
$DEF_JS_BRANCH_NAME=""
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

$ZTMP="New Template Name"
if ( "${JS_TPL_CHK}" -eq ""  -or "${JS_TEMPLATE}" -eq "" ) {    
   if ( "${JS_TPL_CHK}" -ne "" ) {
      Write-Output "Template Name ${JS_TEMPLATE} Already Exists, Please try again ..."
   }
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
## Get container reference...

#Write-Output "${nl}Jetstream Container API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Container API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.template -eq "${JS_TPL_REF}" -and $_.type -eq "JSDataContainer"} | Select-Object

$ZTMP="Container Name"
if ( "${JS_CONTAINER_NAME}" -eq "" ) {
   if ( "${DEF_JS_CONTAINER_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      Write-Output "${ZTMP}s: [copy-n-paste]"
      $b.name
      Write-Output " "
      $JS_CONTAINER_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_CONTAINER_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $JS_CONTAINER_NAME=${DEF_JS_CONTAINER_NAME}
   }
}
Write-Output "template container name: ${JS_CONTAINER_NAME}"

$JS_CONTAINER_REF=$b.reference
#`Write-Output "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .reference '`
Write-Output "template container reference: ${JS_CONTAINER_REF}"

if ( "${JS_CONTAINER_REF}" -eq "" ) {
   Write-Output "${ZTMP} Reference ${JS_CONTAINER_REF} for ${JS_CONTAINER_NAME} not found, Exiting ..."
   exit 1
}

$JS_DC_ACTIVE_BRANCH=$b.activeBranch
#`Write-Output "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .activeBranch '`
Write-Output "Container Active Branch Reference: ${JS_DC_ACTIVE_BRANCH}"

#########################################################
## Get Branch Reference ...

#Write-Output "${nl}Jetstream Branch API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Branch API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.reference -eq "${JS_DC_ACTIVE_BRANCH}" -and $_.type -eq "JSBranch" } | Select-Object

$JS_DAB_NAME=$b.name
#`echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_DC_ACTIVE_BRANCH}"'") | .name '`
echo "Active Branch Name: ${JS_DAB_NAME}"

#TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.dataLayout=="'"${JS_CONTAINER_REF}"'") | .name '`
$b = $a | where { $_.dataLayout -eq "${JS_CONTAINER_REF}" -and $_.type -eq "JSBranch" } | Select-Object

$ZTMP="Branch Name"
if ( "${JS_BRANCH_NAME}" -eq "" ) {
   if ( "${DEF_JS_BRANCH_NAME}" -eq "" ) {
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      $b.name
      echo " "
      $JS_BRANCH_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_BRANCH_NAME}" -eq "" ) {
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $JS_BRANCH_NAME=${DEF_JS_BRANCH_NAME}
   }
}
echo "branch name: ${JS_BRANCH_NAME}"

#
# Parse ...
#
$b = $a | where { $_.name -eq "${JS_BRANCH_NAME}" -and $_.dataLayout -eq "${JS_CONTAINER_REF}" -and $_.type -eq "JSBranch" } | Select-Object
$JS_BRANCH_REF=$b.reference
#`echo "${STATUS}" | jq --raw-output '.result[] | select (.name=="'"${JS_BRANCH_NAME}"'" and .dataLayout=="'"${JS_CONTAINER_REF}"'") | .reference '`
echo "branch reference: ${JS_BRANCH_REF}"

if ( "${JS_BRANCH_REF}" -eq "" ) {
   echo "${ZTMP} Reference ${JS_BRANCH_REF} for ${JS_BRANCH_NAME} not found, Exiting ..."
   exit 1
}

#########################################################
## Command Line Arguments ...

$arrA = "activate","delete","list"
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

#########################################################
## List Branch ...

if ( "${ACTION}" -eq "list" ) {
   #$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/branch/${JS_BRANCH_REF} -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
   $b
   #echo "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_BRANCH_REF}"'")'
   #echo " "
   #echo "# TODO: Fetch some meta data about the branch; such as valid timestamps, bookmarks, etc"
   Remove-Variable -Name * -ErrorAction SilentlyContinue 
   echo " "
   echo "Done ..."
   echo " "
   exit 0
}

#########################################################
## Check / Validate BRANCH Reference ...

if ( "${JS_BRANCH_REF}" -eq "" ) {
   echo "No Branch Name/Reference ${JS_BRANCH_NAME}/${JS_BRANCH_REF} found to ${ACTION}, Exiting ..."
   exit 1;
} elseif ( "${JS_BRANCH_REF}" -eq "${JS_DC_ACTIVE_BRANCH}" ) {
   echo "${JS_BRANCH_NAME} Branch is already Active, unable to ${ACTION}, Exiting ..." 
   exit 1; 
}

#########################################################
## Perform Action on Branch ...

echo "${ACTION} ${JS_BRANCH_NAME} Branch Reference ${JS_BRANCH_REF} ..."

$json=@"
{}
"@

if ( "${ACTION}" -eq "activate" ) {
   $results = (curl.exe -sX POST -k ${BaseURL}/jetstream/branch/${JS_BRANCH_REF}/activate -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
} elseif ( "${ACTION}" -eq "delete" ) {
   $results = (curl.exe -sX POST -k ${BaseURL}/jetstream/branch/${JS_BRANCH_REF}/delete -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
} else {
   echo "Unknown Action: ${ACTION}, nothing executed ..."
   exit 0;
}

$status = ParseStatus "${results}" "${ignore}"
Write-Output "${ACTION} Branch Job Results: ${results}"

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

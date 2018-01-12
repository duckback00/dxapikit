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
# Program Name : jetstream_branch_create_from_bookmark.ps1
# Description  : Delphix API to create Container Branch from Bookmark
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.2
#
# Requirements :
#  1.) curl and jq command line libraries
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#  3.) Include ./jqJSON_subroutines.sh
#  4.) Change values below as required
#
# Interactive Usage:
# ./jetstream_branch_create_from_bookmark.ps1
#
# ... or ...
#
# Non-Interactive Usage:
# ./jetstream_branch_create_from_bookmark.ps1 [template_name] [container_name] [source_branch_name] [source_bookmark_name] [new_branch_name]
#
# ./jetstream_branch_create_from_bookmark.ps1 tpl cdc default BM2 branch_new
# ./jetstream_branch_create_from_bookmark.ps1 tpl cdc default
# ./jetstream_branch_create_from_bookmark.ps1 tpl cdc
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
    [string]$JS_BOOK_NAME = "",
    [string]$BRANCH_NAME = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
# 
# $DEF_JS_TEMPLATE="tpl"		# Jetstream Template Name
# $DEF_JS_CONTAINER_NAME="dc"	# Jetstream Container Name
# $DEF_JS_BRANCH_NAME="default"    # Jetstream Branch Name
# $DEF_JS_BOOK_NAME="BM1"      	# Jetstream Bookmark Name
# $DEF_BRANCH_NAME="break_fix"    # New Jetstream Branch Name
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""       
$DEF_JS_CONTAINER_NAME=""  
$DEF_JS_BRANCH_NAME=""
$DEF_JS_BOOK_NAME=""      
$DEF_BRANCH_NAME=""

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

if ( "${JS_CONTAINER_NAME}" -eq "" ) {
   $ZTMP="Container Name"
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

if ( "${JS_BRANCH_NAME}" -eq "" ) {
   $ZTMP="Branch Name"
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
## Get BookMarks per Branch Option ...

#Write-Output "${nl}Jetstream Bookmark API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Bookmark API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.container -eq "${JS_CONTAINER_REF}" -and $_.branch -eq "${JS_BRANCH_REF}" -and $_.type -eq "JSBookmark" } | Select-Object
#TMP=`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${JS_CONTAINER_REF}"'" and .branch=="'"${JS_BRANCH_REF}"'") | .name '`

if ( "${JS_BOOK_NAME}" -eq "" ) {
   $ZTMP="Bookmark Name"
   if ( "${DEF_JS_BOOK_NAME}" -eq "" ) {
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      $b.name
      echo " "
      $JS_BOOK_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_BOOK_NAME}" -eq "" ) {
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $JS_BOOK_NAME=${DEF_JS_BOOK_NAME}
   }
}
echo "bookmark name: ${JS_BOOK_NAME}"

#
# Parse ...
#
$b = $a | where { $_.container -eq "${JS_CONTAINER_REF}" -and $_.branch -eq "${JS_BRANCH_REF}" -and $_.name -eq "${JS_BOOK_NAME}" -and $_.type -eq "JSBookmark" } | Select-Object
$JS_BOOK_REF=$b.reference
#`echo ${STATUS} | jq --raw-output '.result[] | select(.container=="'"${JS_CONTAINER_REF}"'" and .branch=="'"${JS_BRANCH_REF}"'" and .name=="'"${JS_BOOK_NAME}"'") | .reference '`

#
# Validate ...
#
if ( "${JS_BOOK_REF}" -eq "" ) {
   echo "No Bookmark Name/Reference ${JS_BOOK_NAME}/${JS_BOOK_REF} found, Exiting ..."
   exit 1;
}

echo "Bookmark Reference: ${JS_BOOK_REF}"

#########################################################
#
# Get Remaining Command Line Parameters ...
#

if ( "${BRANCH_NAME}" -eq "" ) {
   if ( "${DEF_BRANCH_NAME}" -eq "" ) {
      echo "---------------------------------"
      echo " "
      $BRANCH_NAME = Read-Host -Prompt "Please Enter New Branch Name (case sensitive)"
      if ( "${BRANCH_NAME}" -eq "" ) {
         echo "No Branch Name Provided, Exiting ..."
         exit 1;
      }
   } else {
      echo "No Branch Name Provided, using Default ..."
      $BRANCH_NAME=${DEF_BRANCH_NAME}
   }
}

#########################################################
## Create Branch Options ...

# Create Branch using Latest Timestamp ...
# Create Branch using specified Timestamp ...
#
# Create Branch using Bookmark ...
#
#=== POST /resources/json/delphix/jetstream/branch ===

$json=@"
{
    \"type\": \"JSBranchCreateParameters\",
    \"dataContainer\": \"${JS_CONTAINER_REF}\",
    \"name\": \"${BRANCH_NAME}\",
    \"timelinePointParameters\": {
        \"type\": \"JSTimelinePointBookmarkInput\",
        \"bookmark\": \"${JS_BOOK_REF}\"
    }
}
"@

echo "JSON: $json"

#########################################################
## Creating Branch ...

Write-Output "Creating Branch ${BRANCH_NAME} from ${JS_BOOK_NAME} ..."
$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/branch -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "Create Branch Job Results: ${results}"

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

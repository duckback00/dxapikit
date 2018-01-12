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
# Program Name : jetstream_bookmark_create_from_timestamp.ps1
# Description  : Delphix API to create a JetStream Bookmark in Active Branch from Timestamp
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: 
# ./jetstream_bookmark_create_from_timestamp.ps1
#
# Non-interactive Usage:
# ./jetstream_bookmark_create_from_timestamp.ps1 [template_name] [container_name] [bookmark_name]    SHARED         TAGS       Timestamp
# ./jetstream_bookmark_create_from_timestamp.ps1 [template_name] [container_name] [bookmark_name] [true|false] ["tag1","tag2"] [YYYY-MM-DDTHH:MI:SS.FFFZ]
#
# Tags are arrays and must be "quoted" if more than one and delimited by a comma
# 
# ./jetstream_bookmark_create.ps1 tpl dc BM3 false '"Hey","There"'
#
# Non-interactive using hardcode defaults iff set: 
# ./jetstream_bookmark_create.ps1 [template_name] [container_name] 
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
    [string]$JS_BOOK_NAME = "",
    [string]$SHARED = "",
    [string]$TAGS = "",
    [string]$TS = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Default Values if not provided on Command Line ... 
#
# For non-interactive defaults ...
# 
# $DEF_JS_TEMPLATE="tpl"
# $DEF_JS_CONTAINER_NAME="dc"
# $DEF_JS_BOOK_NAME="Wally_${DT}"   # JetStream Bookmark Name_append timestamp
# $DEF_SHARED="false"               # Share Bookmark true/false
# $DEF_TAGS='"API","Created"'       # Tags Array Values
# $DEF_TS="2017-12-03T21:11:00.000Z"
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""
$DEF_JS_CONTAINER_NAME=""
$DEF_JS_BOOK_NAME=""
$DEF_SHARED=""
$DEF_TAGS=""
$DEF_TS=""

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

$JS_DC_LAST_UPDATED=$b.lastUpdated
#`Write-Output "${STATUS}" | jq --raw-output '.result[] | select(.template=="'"${JS_TPL_REF}"'" and .name=="'"${JS_CONTAINER_NAME}"'") | .lastUpdated '`

#########################################################
## Get Active Branch Reference ...

#Write-Output "${nl}Jetstream Branch API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/branch/${JS_DC_ACTIVE_BRANCH} -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Branch API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$ACTIVE_BRANCH_NAME=$a.name
#`Write-Output "${STATUS}" | jq --raw-output '.result.name'`
Write-Output "Active Branch Name: ${ACTIVE_BRANCH_NAME}"

#
# Muse use Active Branch ...
#
$JS_BRANCH_REF="${JS_DC_ACTIVE_BRANCH}"

if ( "${JS_BRANCH_REF}" -eq "" ) {
   Write-Output "Branch Reference ${JS_BRANCH_REF} for Active Branch not found, Exiting ..."
   exit 1
}

Write-Output "Active Branch reference: ${JS_BRANCH_REF}"

#Write-Output "${STATUS}" | jq --raw-output '.result[] | select (.reference=="'"${JS_BRANCH_REF}"'")'

#########################################################
## Get Remaining Command Line Parameters ...

$ZTMP="New Bookmark Name"
if ( "${JS_BOOK_NAME}" -eq "" ) {
   if ( "${DEF_JS_BOOK_NAME}" -eq "" ) { 
      Write-Output "---------------------------------"
      $JS_BOOK_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_BOOK_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else { 
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $JS_BOOK_NAME=${DEF_JS_BOOK_NAME}
   }
}


if ( "${SHARED}" -eq "" ) {
   if ( "${DEF_SHARED}" -eq "" ) {
      Write-Output "---------------------------------"
      Write-Output "Options: true | false "
      $SHARED = Read-Host -Prompt "Please Enter Bookmark Sharing Option"
      if ( "${SHARED}" -eq "" ) {
         Write-Output "No Bookmark Name Provided, Exiting ..."
         exit 1;
      }
   } else {    
      Write-Output "No Bookmark Shared Option Provided, using Default ..."
      $SHARED=${DEF_SHARED}
   }
}
$SHARED=$SHARED.ToLower()


if ( "${TAGS}" -eq "" ) {
   if ( "${DEF_TAGS}" -eq "" ) {  
      Write-Output "---------------------------------"
      Write-Output "Each value must be quoted and multiple tags delimited by comma"
      Write-Output "   Single Tag Example: ""REL1.3"""
      Write-Output "Multiple Tags Example: ""API Created"",""REL123"""
      $TAGS = Read-Host -Prompt "Please Enter Bookmark Tags (Enter for no tags)"
      #if ( "${TAGS}" -eq "" ) {
      #   Write-Output "No Bookmark Tags Provided, Exiting ..."
      #   exit 1;
      #}
   } else  {  
      Write-Output "No Bookmark Tags Provided, using Default ..."
      $TAGS=${DEF_TAGS}
   } 
}

if ( "${TAGS}" -eq "" ) {
  $TAGS=""
}

#
# Timestamp ...
#
if ( "${TS}" -eq "" ) {
   if ( "${DEF_TS}" -eq "" ) {
      Write-Output "---------------------------------"
      Write-Output "Timestamp Format: YYYY-MM-DDTHH:MI:SS.FFFZ"
      Write-Output "Container Last Updated: ${JS_DC_LAST_UPDATED}"
      $TS = Read-Host -Prompt "Please Enter Timestamp"
      if ( "${TS}" -eq "" ) {
         Write-Output "No Timestamp Name Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No Timestamp Provided, using Default ..."
      $TS=${DEF_TS}
   }
}

#
# TODO: Validate Command Line Parameter Values ...
# 

#########################################################
# 
# Create Bookmark ...
#  Change parameters as required and desired :) 
#
# Works only for API version 1.8.x or later ..
#
$json=@"
{
    \"type\": \"JSBookmarkCreateParameters\",
    \"bookmark\": {
        \"type\": \"JSBookmark\",
        \"name\": \"${JS_BOOK_NAME}\",
        \"branch\": \"${JS_BRANCH_REF}\",
        \"shared\": ${SHARED},
        \"tags\": [ \"${TAGS}\" ]
    },
    \"timelinePointParameters\": {
        \"type\": \"JSTimelinePointTimeInput\",
        \"branch\": \"${JS_BRANCH_REF}\",
        \"time\": \"${TS}\"
    }
}
"@

#
# Note: the timelinePointParameters type JSTimelinePointLatestTimeInput is the last point / latest time in the branch!
#

Write-Output "JSON: ${json}"

Write-Output "Create Bookmark ${JS_BOOK_NAME} from timestamp ..."
$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/bookmark -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "Bookmark Creation Job Results: ${results}"

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


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
# Program Name : jetstream_template_create.ps1 
# Description  : Delphix API to create a JetStream Template
# Author       : Alan Bitterman
# Created      : 2017-11-20
# Version      : v1.0
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: 
# . .\jetstream_template_create.ps1
#
# Non-Interactive Usage:
#  . .\jetstream_template_create.ps1 [template_name] [dSource_or_VDB_Name] [datasource_name]
#  . .\jetstream_template_create.ps1 tpl2 delphixdb ds2
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
    [string]$DS_NAME = "",
    [string]$JS_DS_NAME = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
#
# $DEF_JS_TEMPLATE="tpl_${DT}" 	# Jetstream Template Name  
# $DEF_JS_DS_NAME="ds_${DT}"   	# JetStream Data Source Name
# $DEF_DS_NAME="delphixdb"	     	# Delphix dSource of VDB Name 
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""
$DEF_JS_DS_NAME=""
$DEF_DS_NAME=""

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
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${JS_TEMAPLTE}" -and $_.type -eq "Group"} | Select-Object

$JS_TPL_CHK=$b.name

if ( "${JS_TPL_CHK}" -ne ""  -or "${JS_TEMPLATE}" -eq "" ) {    
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

#$JS_TPL_CHK=$a | select (.name=="'"${JS_TEMPLATE}"'") | .name

if ( "${JS_TPL_CHK}" -ne "" ) {
   Write-Output "Template Name ${JS_TEMPLATE} Already Exists, Exiting ..."
   exit 1;
}

Write-Output "Template Name: ${JS_TEMPLATE}"

#########################################################
## Get database for datasource ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result

$b = $a | where { $_.provisionContainer -ne ""} | Select-Object
$DS_NAME_REF=$b.provisionContainer

#DS_NAME_REFS=`Write-Output "${STATUS}" | jq --raw-output '.result[] | select (.provisionContainer != null) | .provisionContainer '`
Write-Output "DS_NAME_REFS: ${DS_NAME_REFS}"

if ( "${DS_NAME}" -eq "" ) {
   $ZTMP="Data Source Name"
   if ( "${DEF_DS_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      $a.name
      Write-Output "Valid ${ZTMP}s: [copy-n-paste]"
      $DS_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${DS_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $DS_NAME=${DEF_DS_NAME}
   }
}

$b = $a | where { $_.name -eq "${DS_NAME}" } | Select-Object
$DS_NAME_REF=$b.reference

if ( "${DS_NAME_REF}" -eq "" ) {
   Write-Output "Data Source Reference ${DS_NAME_REF} for ${DS_NAME} not found, Exiting ..."
   exit 1
}

Write-Output "template datasource name: ${DS_NAME}"
Write-Output "template datasource reference: ${DS_NAME_REF}"

#########################################################
## Get Remaining Command Line Parameters ...

if ( "${JS_DS_NAME}" -eq "" ) {
   $ZTMP="Jetstream Data Source Name"
   if ( "${DEF_JS_DS_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      $JS_DS_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_DS_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $JS_DS_NAME=${DEF_JS_DS_NAME}
   }
}

#########################################################
## TODO ## Validate Data Source Object/Names are not already used ...

#STATUS=`curl -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}"`
#RESULTS=$( jqParse "${STATUS}" "status" )
#Write-Output "${STATUS}" | jq "."

#########################################################
## Creating a JetStream Template from an Oracle Database ...

$json=@"
{
     \"type\": \"JSDataTemplateCreateParameters\",
     \"dataSources\": [
         {
             \"type\": \"JSDataSourceCreateParameters\",
             \"source\": {
                 \"type\": \"JSDataSource\",
                 \"priority\": 1,
                 \"name\": \"${JS_DS_NAME}\"
             },
             \"container\": \"${DS_NAME_REF}\"
         }
     ],
     \"name\": \"${JS_TEMPLATE}\"
}
"@

Write-Output "JSON: ${json}"

Write-Output "Create JetStream Template ${JS_TEMPLATE} with Data Source DB ${DS_NAME} ..."

Write-Output "${nl}Create Template API ...${nl}"
$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/template -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "JetStream Template Creation Results: ${results}"

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

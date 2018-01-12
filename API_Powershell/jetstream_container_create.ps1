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
# Program Name : jetstream_container_create.ps1
# Description  : Delphix API to create a JetStream Container
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: 
# ./jetstream_container_create.ps1
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
    [string]$JS_DS_NAME = "",
    [string]$JS_DC_NAME = "",
    [string]$DS_NAME = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1

#
# Default Values if not provided on Command Line ...
#
# For non-interactive defaults ...
# 
# $DEF_JS_TEMPLATE="tpl"           # JetStream Template Name
# $DEF_JS_DS_NAME="ds"             # JetStream Template Data Source Name
# $DEF_JS_DC_NAME="dc"             # JetStream Data Container Name
# $DEF_DS_NAME="VBITT2" 		# Database Data Source VDB 
#
# For full interactive option, set default values to nothing ...
#
$DEF_JS_TEMPLATE=""
$DEF_JS_DS_NAME=""
$DEF_JS_DC_NAME=""
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
# Convert Results String to JSON Object and Get Results ...
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

$b = $a | where { $_.name -eq "${JS_TEMPLATE}" -and $_.type -eq "JSDataTemplate"} | Select-Object
$JS_TPL_REF=$b.reference 

if ( "${JS_TPL_REF}" -eq "" ) {
   Write-Output "${ZTMP} Reference ${JS_TPL_REF} for ${JS_TEMPLATE} not found, Exiting ..."
   exit 1;
}

Write-Output "template reference: ${JS_TPL_REF}"

#$JS_ACTIVE_BRANCH_REF=$b.activeBranch
#Write-Output "active template branch reference: ${JS_ACTIVE_BRANCH_REF}"

#########################################################
## Get JetStream sourceDataLayout ...

#Write-Output "${nl}Jetstream DataSource API ...${nl}"
$results = (curl.exe -s -X GET -k ${BaseURL}/jetstream/datasource -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "DataSource API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.name -eq "${JS_TEMAPLTE}" -and $_.type -eq "Group"} | Select-Object

if ( "${JS_DS_NAME}" -eq "" ) {
   $ZTMP="Template Data Source Name"
   if ( "${DEF_JS_DS_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      Write-Output "${ZTMP}s: [copy-n-paste]"
      $a.name
      Write-Output " "
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

#
# Parse ...
#
$b = $a | where { $_.name -eq "${JS_DS_NAME}" -and $_.type -eq "JSDataSource"} | Select-Object

$JS_DATALAYOUT=$b.dataLayout
#`Write-Output ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_DS_NAME}"'") | .dataLayout '`
Write-Output "JetStream sourceDataLayout: ${JS_DATALAYOUT}"

$JS_DS_REF=$b.container
#`Write-Output ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${JS_DS_NAME}"'") | .container '`
Write-Output "JetStream data source parent container: ${JS_DS_REF}"

#########################################################
## Get database for container datasource ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.provisionContainer -eq "${JS_DS_REF}" } | Select-Object
$DS_NAME_REFS=$b.reference
#Write-Output "DS_NAME_REFS: ${DS_NAME_REFS}"

if ( "${DS_NAME}" -eq "" ) {
   $ZTMP="Data Source Name"
   if ( "${DEF_DS_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      foreach ($a1 in $DS_NAME_REFS) {
         if ( "$a1" -ne "" ) {
            #Write-Output "Array Value: |$a1|"
            $b = $a | where { $_.reference -eq "${a1}" } | Select-Object
            $b.name
         }
      }
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

if ( "${JS_DC_NAME}" -eq "" ) {
   $ZTMP="Jetstream Container Name"
   if ( "${DEF_JS_DC_NAME}" -eq "" ) {
      Write-Output "---------------------------------"
      $JS_DC_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${JS_DC_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else {
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $JS_DC_NAME=${DEF_JS_DC_NAME}
   }
}

Write-Output "jetstream container name: ${JS_DC_NAME}"

#########################################################
## TODO ## Validate Data Container Object/Names are not already used ...

#
# Type Option for API version 190 or later
# Faster Container Creations ...
#
#{
#	"template":"JS_DATA_TEMPLATE-8"
#	,"owners":["USER-2"]
#	,"name":"dc"
#	,"dataSources":[{
#		"source":{"priority":1,"name":"ds","type":"JSDataSource"}
#	   ,"container":"ORACLE_DB_CONTAINER-37"
#	   ,"type":"JSDataSourceCreateParameters"
#	 }]
#	 ,"properties":{}
#	,"type":"JSDataContainerCreateWithoutRefreshParameters"
#}
# NOTICE: no timelinePointParameters name: values

#########################################################
## Creating a JetStream Container from an Oracle Database ...

$json=@"
{
     \"type\": \"JSDataContainerCreateWithRefreshParameters\",
     \"dataSources\": [
         {
             \"type\": \"JSDataSourceCreateParameters\",
             \"source\": {
                 \"type\": \"JSDataSource\",
                 \"priority\": 1,
                 \"name\": \"${DS_NAME}\"
             },
             \"container\": \"${DS_NAME_REF}\"
         }
     ],
     \"name\": \"${JS_DC_NAME}\",
     \"template\": \"${JS_TPL_REF}\",
     \"timelinePointParameters\": {
         \"type\": \"JSTimelinePointLatestTimeInput\",
         \"sourceDataLayout\": \"${JS_DATALAYOUT}\"
     }
}
"@

Write-Output "JSON: ${json}"

Write-Output "Create JetStream Container ${JS_DC_NAME} with Data Source DB ${DS_NAME} ..."
$results = (curl.exe -sX POST -k ${BaseURL}/jetstream/container -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "JetStream Template Container Creation Results: ${results}"

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

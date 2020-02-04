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
# Program Name : provision_sqlserver_i.ps1
# Description  : Delphix PowerShell API provision VDB Example  
# Author       : Alan Bitterman
# Created      : 2017-12-15
# Version      : v1.2
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Interactive Usage: 
# . .\provision_sqlserver_i.ps1 
#
# Non-Interactive Usage: 
# . .\provision_sqlserver_i.ps1 [dSource] [VDB_Name] [Group]          [Environment]  [Instance]
# . .\provision_sqlserver_i.ps1 delphixdb Vdelphixdb "Windows_Target" "Windows Host" "MSSQLSERVER"
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Get Command Line Arguements ...
## (must be first thing in file)

param (
    [string]$SOURCE_SID = "",
    [string]$VDB_NAME = "",
    [string]$TARGET_GRP = "",
    [string]$TARGET_ENV = "",
    [string]$TARGET_REP = ""
)

#########################################################
## Parameter Initialization ...

. .\delphix_engine_conf.ps1



## Default Values if not provided on Command Line ... 

#
# For non-interactive defaults ...
# 
# $DEF_SOURCE_SID="delphixdb"           # dSource name used to get db container reference value
# $DEF_VDB_NAME="Vdelphixdb"            # Delphix VDB Name
# $DEF_TARGET_GRP="Windows_Target"      # Delphix Engine Group Name
# $DEF_TARGET_ENV="Windows Host"        # Target Environment used to get repository reference value 
# $DEF_TARGET_REP="MSSQLSERVER"         # Target Environment Repository / Instance name

#
# For full interactive option, set default values to nothing ...
#
$DEF_SOURCE_SID=""
$DEF_VDB_NAME=""
$DEF_TARGET_GRP=""
$DEF_TARGET_ENV=""
$DEF_TARGET_REP=""


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
## API Version ...

$apival=Get_APIVAL "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" 
Write-Output "API Version: ${apival} "

#########################################################
## Get database container ...

#Write-Output "Database API ..."
$results = (curl.exe -sX GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
#$b = $a | where { $_.type -eq "MSSqlDatabaseContainer" } | Select-Object
$b = $a | where { $_.os -eq "Windows" } | Select-Object

# 
# Prompt for dSource or VDB Name ...
#
if ("${SOURCE_SID}" -eq "") {
   $ZTMP="dSource or VDB Source"
   if ( "${DEF_SOURCE_SID}" -eq "" ) {
      Write-Output "--------------------------------------"
      Write-Output "${ZTMP}: [copy-n-paste]"
      $b.name
      $SOURCE_SID = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ("${SOURCE_SID}" -eq "" ) { 
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $SOURCE_SID=${DEF_SOURCE_SID}
   }
}

#
# Parse Results (cont) ...
#
$b = $a | where { $_.name -eq "${SOURCE_SID}" -and $_.type -eq "MSSqlDatabaseContainer" } | Select-Object
$CONTAINER_REFERENCE=$b.reference
Write-Output "container reference: ${CONTAINER_REFERENCE}"

if ("${CONTAINER_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No container found for ${SOURCE_ID} ${CONTAINER_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## VDB Name from Command Line Parameters ...

$ZTMP="New VDB Name"
if ( "${VDB_NAME}" -eq "" ) {
   if ( "${DEF_VDB_NAME}" -eq "" ) { 
      Write-Output "---------------------------------"
      $VDB_NAME = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ( "${VDB_NAME}" -eq "" ) {
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      }
   } else { 
      Write-Output "No ${ZTMP} Provided, using Default ..."
      $VDB_NAME=${DEF_VDB_NAME}
   }
}
echo "${ZTMP}: ${VDB_NAME}"

#########################################################
## Get Group Reference ...

#Write-Output "Group API ..."
$results = (curl.exe -sX GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Group API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result

# 
# Prompt for Group Name ...
#
$ZTMP="Delphix Target Group/Folder"
if ("${TARGET_GRP}" -eq "") {
   if ( "${DEF_TARGET_GRP}" -eq "" ) {
      Write-Output "--------------------------------------"
      Write-Output "${ZTMP}: [copy-n-paste]"
      $a.name
      $TARGET_GRP = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ("${TARGET_GRP}" -eq "" ) { 
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $TARGET_GRP=${DEF_TARGET_GRP}
   }
}

#
# Parse Results (cont) ...
#-and $_.type -eq "MSSqlDatabaseContainer"
#
$b = $a | where { $_.name -eq "${TARGET_GRP}"} | Select-Object
$GROUP_REFERENCE=$b.reference
Write-Output "group reference: ${GROUP_REFERENCE}"

if ("${GROUP_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No ${ZTMP} found for ${TARGET_GRP} ${GROUP_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## Get Environment reference ...

#Write-Output "Environment API ..."
$results = (curl.exe -sX GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "environment API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.type -eq "WindowsHostEnvironment" } | Select-Object

# 
# Prompt for Group Name ...
#
$ZTMP="Target Environment"
if ("${TARGET_ENV}" -eq "") {
   if ( "${DEF_TARGET_ENV}" -eq "" ) {
      Write-Output "--------------------------------------"
      Write-Output "${ZTMP}: [copy-n-paste]"
      $b.name
      $TARGET_ENV = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ("${TARGET_ENV}" -eq "" ) { 
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $TARGET_ENV=${DEF_TARGET_ENV}
   }
}

#
# Parse Results (cont) ...
#
$b = $a | where { $_.name -eq "${TARGET_ENV}"} | Select-Object
$ENV_REFERENCE=$b.reference
Write-Output "environment reference: ${ENV_REFERENCE}"

if ("${ENV_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No ${ZTMP} found for ${TARGET_ENV} ${ENV_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## Get Repository reference ...

#Write-Output "${nl}Calling repository API ...${nl}"
$results = (curl.exe --insecure -sX GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "repository API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results ...
#
$o = ConvertFrom-Json $results
$a = $o.result
$b = $a | where { $_.environment -eq "${ENV_REFERENCE}" } | Select-Object

# 
# Prompt for Group Name ...
#
$ZTMP="Target SQL Server Instance"
if ("${TARGET_REP}" -eq "") {
   if ( "${DEF_TARGET_REP}" -eq "" ) {
      Write-Output "--------------------------------------"
      Write-Output "${ZTMP}: [copy-n-paste]"
      $b.name
      $TARGET_REP = Read-Host -Prompt "Please Enter ${ZTMP} (case sensitive)"
      if ("${TARGET_REP}" -eq "" ) { 
         Write-Output "No ${ZTMP} Provided, Exiting ..."
         exit 1
      }
   } else {
      echo "No ${ZTMP} Provided, using Default ..."
      $TARGET_REP=${DEF_TARGET_REP}
   }
}

#
# Parse Results (cont) ...
#
$b = $a | where { $_.name -eq "${TARGET_REP}" -and $_.environment -eq "${ENV_REFERENCE}"} | Select-Object
$REP_REFERENCE=$b.reference
Write-Output "repository/instance reference: ${REP_REFERENCE}"

if ("${REP_REFERENCE}" -eq "" ) { 
   Write-Output "Error: No ${ZTMP} found for ${TARGET_REP} ${REP_REFERENCE}, Exiting ..."
   exit 1
}

#########################################################
## Provision a SQL Server Database ...

$json = @"
{
    \"type\": \"MSSqlProvisionParameters\",
    \"container\": {
        \"type\": \"MSSqlDatabaseContainer\",
        \"name\": \"${VDB_NAME}\",
        \"group\": \"${GROUP_REFERENCE}\",
        \"sourcingPolicy\": {
            \"type\": \"SourcingPolicy\",
            \"loadFromBackup\": false,
            \"logsyncEnabled\": false
        },
        \"validatedSyncMode\": \"TRANSACTION_LOG\"
    },
    \"source\": {
        \"type\": \"MSSqlVirtualSource\", 
"@

#
# Auto Restart Option starting with API Version 1.8.x ...
#
if ( $apival -gt 180 ) {

$json = @"
${json}
        \"allowAutoVDBRestartOnHostReboot\": false, 
"@

}

#
# Continue to build JSON string ...
#
$json1 = @"
${json}
        \"operations\": {
            \"type\": \"VirtualSourceOperations\",
            \"configureClone\": [],
            \"postRefresh\": [],
            \"postRollback\": [],
            \"postSnapshot\": [],
            \"preRefresh\": [],
            \"preSnapshot\": []
        }
    },
    \"sourceConfig\": {
        \"type\": \"MSSqlSIConfig\",
        \"linkingEnabled\": false,
        \"repository\": \"${REP_REFERENCE}\",
        \"databaseName\": \"${VDB_NAME}\",
        \"recoveryModel\": \"SIMPLE\",
        \"instance\": {
            \"type\": \"MSSqlInstanceConfig\",
            \"host\": \"${ENV_REFERENCE}\"
        }
    },
    \"timeflowPointParameters\": {
        \"type\": \"TimeflowPointSemantic\",
        \"container\": \"${CONTAINER_REFERENCE}\",
        \"location\": \"LATEST_SNAPSHOT\"
    }
}
"@


Write-Output "JSON: $json1"

#
# NOTE: the above JSON does change with the upcomming Delphix J release API Version 1.9.0? 
#

#Write-Output "${nl}Calling database provision API ...${nl}"
$results = (curl.exe --insecure -sX POST -k ${BaseURL}/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json1}")
$status = ParseStatus "${results}" "${ignore}"
Write-Output "database provision API Results: ${results}"

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
$JOB=$o.job
Write-Output "Job # ${JOB}"

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

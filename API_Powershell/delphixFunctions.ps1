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
# Program Name : delphixFunctions.ps1
# Description  : Delphix PowerShell API Functions  
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.3
#
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#
# Include Delphix Functions in Scripts ...
#
# Usage: . .\delphixFunctions.ps1
#
#########################################################
#                   DELPHIX CORP                        #
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

# 
# JSON Parsing for Powershell version 2.0
#
Function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}
Function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}

#
# Delphix Data Platform APIs ...
# 
Function RestSession([string]$DMUSER, [string]$DMPASS, [string]$BaseURL, [string]$COOKIE, [string]$CONTENT_TYPE){
   $nl = [Environment]::NewLine
   #Write-Output "${nl} Parameters: $DMUSER $DMPASS $COOKIE ${nl}"
   #
   # Session JSON Data ...
   #
   $json = @"
{
    \"type\": \"APISession\",
    \"version\": {
        \"type\": \"APIVersion\",
        \"major\": 1,
        \"minor\": 8,
        \"micro\": 0
    }
}
"@

   #Write-Output "${nl}${json}${nl}" 
   #
   # Delphix Curl Session API ... 
   #
   #Write-Output "${nl}Calling Session API ...${nl}"
   $results = (curl.exe -sX POST -k ${BaseURL}/session -c "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
   $status = ParseStatus "${results}" "${ignore}"
   #Write-Output "Session API Results: ${results}"  
   # 
   # Login JSON Data ...
   #
   $json = @"
{
    \"type\": \"LoginRequest\",
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@
   #Write-Output "${nl}${json}${nl}"
   #
   # Delphix Curl Login API ...
   #
   #Write-Output "${nl}Calling Login API ...${nl}"
   $results = (curl.exe -sX POST -k ${BaseURL}/login -b "${COOKIE}" -H "${CONTENT_TYPE}" -d "${json}")
   $status = ParseStatus "${results}" "${ignore}"
   #Write-Output "${nl}Login API Results: ${results}"

   return [string]$results
}

Function ParseStatus([string] $item, [string]$ignore){
   $nl = [Environment]::NewLine
   $status="Error"
   # Write-Output "item $item"
   try {
      $o = ConvertFrom-Json $item
      $status=$o.status                       #Write-Output "Status ... $status ${nl}"
      if ("${status}" -ne "OK") {
         Write-Output "Job Failed with ${status} Status ${nl}${results}${nl}"
      }
   } catch {
     Write-Output "ERROR: Invalid JSON Content ... ${nl}${item}${nl}"
     $status="ERROR: ${item}"
   }    
   if ( "$status" -ne "OK" -and "${ignore}".ToUpper() -eq "NO") {
      Write-Output "Exiting ..."
      exit 1
   }
   return [string]$status
}


############################################
## Get API Version ...
 
Function Get_APIVAL([string]$BaseURL, [string]$COOKIE, [string]$CONTENT_TYPE){
   #
   # Delphix About API ... 
   #
   #Write-Output "${nl}Calling Session API ...${nl}"
   $results = (curl.exe -sX GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}")
   $status = ParseStatus "${results}" "${ignore}"
   #Write-Output "About API Results: ${results}"  

   $o = ConvertFrom-Json $results
   $a = $o.result
   $b = $a.apiVersion
   $major=$b.major
   $minor=$b.minor
   $micro=$b.micro
   $apival="${major}${minor}${micro}"
   #Write-Output "API Version $apival ${nl}"

   #
   if ( "$apival" -eq "") {
      Write-Output "ERROR: Delphix Engine API Version Value Unknown, $apival, Exiting ..."
      exit 1
   }
   return [string]$apival
}

############################################
## Monitor Job Status ...
 
Function Monitor_JOB ([string]$BaseURL, [string]$COOKIE, [string]$CONTENT_TYPE, [string]$JOB) {
   #
   # Verify ...
   #
   if ( "${JOB}" -eq "" ) {
      return [string] "ERROR: Missing Job ${JOB} Number"
   }
   # 
   # Job Information ...
   #
   #Write-Output "${nl}Calling job API ...${nl}"
   $results = (curl.exe -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
   $status = ParseStatus "${results}" "${ignore}"
   #Write-Output "job API Results: ${results}"

   # 
   # Get Job Status and Job Information ...
   #
   $o = ConvertFrom-Json $results
   $a = $o.result
   $JOBSTATE=$a.jobState
   $PERCENTCOMPLETE=$a.percentComplete
   Write-Output "jobState  $JOBSTATE"
   Write-Output "percentComplete $PERCENTCOMPLETE"
   $d = Get-Date
   if ( "${JOBSTATE}" -ne "COMPLETED" ) {
      Write-Output "***** waiting for status *****"
      DO
      {
         $d = Get-Date
         Write-Output "Current status as of ${d} : ${JOBSTATE} : ${PERCENTCOMPLETE}% Completed"
         sleep ${DELAYTIMESEC}
         $results = (curl.exe -sX GET -k ${BaseURL}/job/${JOB} -b "${COOKIE}" -H "${CONTENT_TYPE}")
         $status = ParseStatus "${results}" "${ignore}"
         $o = ConvertFrom-Json $results
         $a = $o.result
         $JOBSTATE=$a.jobState
         $PERCENTCOMPLETE=$a.percentComplete
      } While ($JOBSTATE -contains "RUNNING")
   }

   #########################################################
   ##  Producing final status

   if ("${JOBSTATE}" -eq "COMPLETED") {
      return [string] "${JOB} ${JOBSTATE} Succesfully."
   } else {
      return [string] "${JOB} Failed with ${JOBSTATE} Status"
   }
}           # End of Monitor_JOB Function ...

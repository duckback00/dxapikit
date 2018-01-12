#!/bin/sh
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
# Program Name : about.ps1
# Description  : Delphix API about call 
# Author       : Alan Bitterman
# Created      : 2017-08-12
# Version      : v1.0
#
# Requirements :
#  1.) curl command line executable and ConvertFrom-Json Commandlet
#  2.) Populate Delphix Engine Connection Information . .\delphix_engine_conf.ps1
#  3.) Include Delphix Functions . .\delphixFunctions.ps1
#  4.) Change values below as required
#
# Usage: . \about.ps1
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

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
## About API Call ...

#Write-Output "${nl}Calling Database API ...${nl}"
$results = (curl.exe -sX GET -k ${BaseURL}/about -b "${COOKIE}" -H "${CONTENT_TYPE}")
$status = ParseStatus "${results}" "${ignore}"
#Write-Output "Database API Results: ${results}"

#########################################################
## Some parsing examples ...

Write-Output "${nl}API Version ... " 

#
# Convert Results String to JSON Object and Get Results Status ...
#
$o = ConvertFrom-Json $results
#$o
$a = $o.result
#$a

$b = $a.apiVersion
$b

#
# Get Delphix Engine Build Version ...
# 
$major=$b.major
$minor=$b.minor
$micro=$b.micro

$apival=[int]("${major}"+"${minor}"+"${micro}")
Write-Output "Delphix Engine API Version: ${apival}"

if ( $apival -le 0 ) {
  Write-Output "Error: Delphix Engine API Version Value Unknown $apival ..."
} else {
  if ( $apival -lt 180 ) {
      Write-Output "before Illium"
   } else {
      Write-Output "Illium or later"
   }
}

#
# Get Delphix Engine Enabled Features ...
# 
Write-Output "${nl}Features ... ${nl}" 

$arr = $o.result.enabledFeatures
foreach ($a1 in $arr) {
   Write-Output "Array Value: |$a1|"
}
Write-Output "Index: " $arr[0]

############## E O F ####################################
## Clean up and Done ...

Remove-Variable -Name * -ErrorAction SilentlyContinue
Write-Output " "
Write-Output "Done ..."
Write-Output " "
exit 0

# dxapikit

# **Delphix API toolkit**

## What is it?

DxAPIkit is a set of scripts, which are provided by Delphix personnel. DxAPIkit scripts constist of Mac/Unix/Linux shell scripts and Windows PowerShell scripts. 

- API
- API_Powershell 

The Windows PowerShell scripts utilize the provided JSON parser functions (or native JSON parser module after PowerShell version 3) while the Mac/Unix/Linux shell scripts require the jq command line JSON parser.  

All scripts require the curl command line library. 

The scripts are provided as shell scripts and can be easily ported to your favorite programming language of choice if desirable. Knowledge of the Delphix Engine is required with limited programming experience recommended to use the DxAPIkit. 

The goal for this project is to help Delphix users get up to speed quickly on how to use the Delphix API's.


## What's new?

   Please check a change log for list of changes.

## How to get started

   Check a documentation for more details
   https://docs.delphix.com/docs/files/77120152/77121389/1/1501725989988/So+you+want+to+work+with+Delphix+APIs.pdf

## Delphix Engine Versions Tested
- 5.1.5
- 5.1.6
- 5.1.7

## Required Packages

curl://

curl is command line tool and library for transferring data with URLs 
- NOTE: The curl command library is included with most operating systems
- References: https://github.com/curl/curl     https://curl.haxx.se/
- Versions Tested: curl 7.19.7 
  

./jq 

jq is a lightweight and flexible command-line JSON processor
- Required for **Mac/Unix/Linux Platforms ONLY**
- References: https://stedolan.github.io/jq/  
- Versions Tested: jq version 1.3
	
	      
## Legalness

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


## Other Projects of Interest

**dxtoolkit** Great Perl Library of Programs that use the Delphix API
https://github.com/delphix/dxtoolkit


## Preface

What is RESTFul?  API?  JSON?  CLI?  Object Reference?  GET/POST?  Cookies?  HTTP/HTTPS? cURL?  Where do I begin?  Who can help me?  Documentation?  Tutorials?  That’s great for Linux, but I am on Windows?  Parse?  Don’t have a clue about sed, awk, grep, cut, and other acronyms. What about Regular Expressions, like “Hello”?

Just a small sampling of questions that you may or may not know the answers to, let alone learning Delphix and a programming language. Delphix is a technical product, and being new to the Delphix family can be a bit overwhelming. The goal for the referenced document is simple, to enable users to get up to speed quickly on how to use Delphix APIs. 

Hope you find it useful! 

Regards,

Bitt... 

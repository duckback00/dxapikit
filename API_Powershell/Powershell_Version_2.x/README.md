## Powershell 2.0 Scripts

<p>This branch contains some basic Powershell version 2.0 Delphix API scripts. </p> 

<p>Prior to Powershell 3.x or later versions, Powershell did NOT include any JSON parsing commandlets. So to work with Delphix APIs, JSON parsing functions where required / created within the delphixFunctions.ps1 script. These functions operate the same as the native 3.x or later functions respectively.  So if you have a Powershell v2.x environment, the Powershell scripts using the native commandlets calls, can be easily back-ported to v2.x by changing the commandlet calls to use the functions, i.e.  Replace ConvertFrom-Json with ConvertFrom-Json20 calls throughout the scripts. </p>

<hr />
  

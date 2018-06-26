# README.md

## Masking APIs via Windows Powershell Scripts

Disclaimer: As always, these scripts are provided "as-is" and the end user is responsible for the application and usage of these scripts within their environment. Test, verify, re-test, and re-verify prior to using any code into production. 

These scripts are basic examples and some require manual editing of the files for configuring the parameter values for the respective environment and operations. 


### Requirements 
============


### PowerShell Version 
------------------
Windows has a number of versions of PowerShell. The minimum version for Delphix is 2.0 for SQL Server 2008 environments. There are numerous enhancements and features with subsequent Powershell versions. 

These examples are for PowerShell 3.0 or later. Starting with PowerShell 3.0 and later, native JSON parsing modules are included in PowerShell. In PowerShell 2.0 there are no JSON parsing modules, so there are functions included to support Poweshell 2.x versions.  

<pre>
Example

PS> $PSVersionTable.PSVersion
Major Minor Build Revision
----- ----- ----- --------
5      1     14393    2312
</pre>


### Execution of Scripts Security Disabled
--------------------------------------

It is possible to disable Powershell environments on the system. If they are disabled, you will see the following error for any Powershell script that you try to execute.

<pre>
PS> . .\[any_powershell_script].ps1

File [any_powershell_script].ps1 cannot be loaded because the execution of scriptsis disabled on this system. Please see "get-help about signing" for more details.

At line:1 char:2
+ . <<<< .\ [any_powershell_script].ps1
 + CategoryInfo : NotSpecified: (:) [], PSSecurityException
 + FullyQualifiedErrorId : RuntimeException

To enable Powershell scripts to be executed, set the execution policy to Yes.

PS> set-executionpolicy remotesigned
Execution Policy Change

The execution policy helps protect you from scripts that you do not trust. Changing the execution policy might expose you to the security risks described in the about_Execution_Policies help topic. Do you want to change the execution policy?
[Y] Yes [N] No [S] Suspend [?] Help (default is "Y"): Y

PS>
</pre>

Now your shell scripts will be executed.




### curl.exe
--------

NOTE:
Not all Windows platforms have the cURL executable installed. 


METHOD 1: Install the git+ client for Windows	
---------------------------------------------

https://git-for-windows.github.io/
The Git install includes, among other things, curl.exe. After installing, the /mingw64/bin will be added to your PATH. Then you will be able to use the curl command from the Windows Command Prompt or PowerShell console.

<pre>
PS> curl.exe --version
curl 7.49.1 (x86_64-w64-mingw32) libcurl/7.49.1 OpenSSL/1.0.2h zlib/1.2.8
libidn/1.32 libssh2/1.7.0 nghttp2/1.12.0 librtmp/2.3
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s
rtmp rtsp scp sftp smtp smtps telnet tftp
Features: IDN IPv6 Largefile SSPI Kerberos SPNEGO NTLM SSL libz TLS-SRP HTTP2
</pre>


METHOD 2: Download the curl.exe binary executable and copy it to the Windows directory
--------------------------------------------------------------------------------------

========================= curl.exe executable download =========================

https://curl.haxx.se/dlwiz/

<pre>
Click on "curl executable" link
Select Operating System: 					Win64  		Select! 
Select for What Flavour: 					Generic  	Select!
Select which Win64 Version: Show package for Win64 version: 	Any  		Select!
Select for What CPU: Show package for Win64 version: 		x_86_64  	Select!

Select latest stable version with SSH enabled 
The latest stable version available (7.60.0)!

curl version: 7.60.0 - SSL enabled SSH enabled   [ Download ]  
</pre>


To install:
1.) Download the .zip file from the website steps shown above.

2.) Copy .zip file to computer

3.) Either add the path below to the default system PATH environment variable   

[full_path_to]\curl-7.60.0-win64-mingw\bin 
... or ...
copy the contents of the \bin directory, curl.exe, *.crt and libcurl-x64.dll, to the Windows\System32 directory

4.) From Powershell, type the following command

<pre>
PS> curl.exe --version
curl 7.60.0 ... [ more version info to follow ]
</pre>




Invoking the curl or curl.exe from Powershell command line.

<pre>
PS> Get-Command curl
CommandType Name 
----------- ---- 
Alias curl -> Invoke-WebRequest
</pre>

<pre>
PS> Get-Command curl.exe
CommandType Name  Version  Source
----------- ----  ----------  -------
Application curl.exe  7.60.0.0  C:\Windows\system32\curl.exe
</pre>

If the alias curl name is to the Invoke-WebRequest, you will need to use the curl.exe command explicitly or remove the alias. Recommend that you just use the curl.exe explicitly.

Verify that curl.exe works from the respective Powershell environment:

<pre>
PS> curl.exe --version
curl 7.60.0 (x86_64-pc-win32) ...
</pre>

----------------------------------------------------------------------------------------------------


### Masking Scripts

- Powershell Masking Job Script .................. Filename: masking.ps1



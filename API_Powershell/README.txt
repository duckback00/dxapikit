README.txt
v1.0

** So you want to work with the Delphix APIs? **

Disclaimer: As always, these scripts are provided "as-is" and the end user is responsible
for the application and usage of these scripts within their environment. Test, verify, 
re-test, and re-verify prior to using any code into production. 

These scripts are basic examples and some require manual editing of the files for configuring 
the parameter values for the respective environment and operations. 

First, update the    delphix_engine.conf   file for your Delphix Engine connection information!

# 
# Delphix Engine Config File ...
#
# Replace Delphix Engine IP Address, replace 127.0.0.1 with your DE IP Address 
# Replace Account Credentials 
#

vi delphix_engine.conf
...
DMIP="172.16.160.195"             # include port if required, "172.16.160.195:80" or :443
DMUSER=delphix_admin
DMPASS=delphix
...
[save & exit]




Appendix
--------

Technical	NOTE: Powershell Open Source is now available for Linux and Mac OS.
https://techcrunch.com/2016/08/18/microsoft-open-sources-powershell-brings-it-tolinux-and-os-x/


Windows	PowerShell
==================


Requirements 
============


Powershell Version 
------------------
Windows has a number of versions of Powershell. The minimum version for Delphix is 2.0 for SQL Server 2008 environments. There are numerous enhancements and features with subsequent Powershell versions. Additionally, you must be aware of the architecture of 32bit or 64bit Powershell versions you are running from within.

PS> $PSVersionTable.PSVersion
Major Minor Build Revision
----- ----- ----- --------
2      0     -1    -1


32bit or 64bit
--------------

If executing Powershell scripts from within Delphix Pre/Post Scripts commands or Delphix hooks, the default Powershell used is 32 bit, whereas the typical default Windows Powershell is 64 bit. However, Powershell allows you to execute 64 bit Powershell command from within the 32 bit environment. Shown below is a simple alias, ps64,  to execute 64bit Powershell scripts.

PS> set-alias ps64 "$env:windir\sysnative\WindowsPowerShell\v1.0\powershell.exe"

Sample call to execute 64bit Powershell script

PS> ps64 [path\to\any_64bit_powershell_script].ps1

Courtesy of this article:
http://www.gregorystrike.com/2011/01/27/how-to-tell-if-powershell-is-32-bit-or-64-bit/

PS> if ($env:Processor_Architecture -eq "x86") { write "running on 32bit" } else
{write "running on 64bit"}
running on 32bit
.	.	.	or	.	.	.
PS> if ([System.IntPtr]::Size -eq 4) { "32-bit" } else { "64-bit" }
32-bit

It is worth noting that the locations of the 32-bit and 64-bit versions of Powershell are somewhat misleading. The 32-bit PowerShell is found at

C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe

and the 64-bit PowerShell is at
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe



Execution of Scripts Security Disabled
--------------------------------------

It is possible to disable Powershell environments on the system. If they are disabled, you will see the following error for any Powershell script that you try to execute.

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

Now your shell scripts will be executed.



curl.exe
--------

NOTE:
Not all Windows platforms have the cURL executable installed. The easiest method I found was to install the git+ client for Windows.	

https://git-for-windows.github.io/
The Git install includes, among other things, curl.exe. After installing, the /mingw64/bin will be added to your PATH. Then you will be able to use the curl command from the Windows Command Prompt or PowerShell console.

PS> which curl.exe
/mingw64/bin/curl

PS> curl.exe --version
curl 7.49.1 (x86_64-w64-mingw32) libcurl/7.49.1 OpenSSL/1.0.2h zlib/1.2.8
libidn/1.32 libssh2/1.7.0 nghttp2/1.12.0 librtmp/2.3
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s
rtmp rtsp scp sftp smtp smtps telnet tftp
Features: IDN IPv6 Largefile SSPI Kerberos SPNEGO NTLM SSL libz TLS-SRP HTTP2

Invoking	the	curl or	curl.exe from	Powershell	command	line.	

PS> Get-Command curl
CommandType Name ModuleName
----------- ---- ----------
Alias curl -> Invoke-WebRequest

PS> Get-Command curl.exe
CommandType Name ModuleName
----------- ---- ----------
Application curl.exe

If the alias curl name is to the Invoke-WebRequest, you will need to use the curl.exe command explicitly or remove the alias.

PS> Remove-item alias:curl

Verify that curl and/or	curl.exe	work	from	the	respective	Powershell environment:

PS> curl.exe --version
curl 7.49.1 (x86_64-w64-mingw32) ...

PS> curl --version
curl 7.49.1 (x86_64-w64-mingw32) ...



Sample Scripts
--------------

Authentication
	Windows Powershell Authentication           Filename: auth1.ps1

Windows / SQL Server
	Powershell Functions 							          Filename: parseFunctions.ps1
	Create a Windows Target Environment				  Filename: create_window_target_env.ps1
	Link/Ingest a SQL Server dSource  				  Filename: link_sqlserver.ps1
	Provision a SQL Server VDB 						      Filename: provision_sqlserver.ps1
	Provision a VDB from a VDB 						      Filename: provision_sqlserver_child.ps1
	Delete a dSource or Virtural Database			  Filename: delete_database_sqlserver.ps1
	Refresh a VDB with Powershell					      Filename: windows_sqlserver_refresh.txt


*** WIP contact me for details or updates ***

Hooks
Filename: link_hook_sqlserver.sh
Filename: vdb_hook_sqlserver.sh


*** End of README.txt ***

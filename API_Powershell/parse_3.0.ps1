
#
# Variables ...
#
$nl = [Environment]::NewLine

#
# Use Delphix system API JSON results Example ...
#
$json='{"type":"OKResult","status":"OK","result":{"type":"SystemInfo","productType":"standard","productName":"Delphix Engine","buildTitle":"Delphix Engine 5.1.1.0","buildTimestamp":"20160721T07:23:41.000Z","buildVersion":{"type":"VersionInfo","major":5,"minor":1,"micro":1,"patch":0},"configured":true,"enabedFeatures":["XPP","MSSQLHOOKS"],"apiVersion":{"type":"APIVersion","major":1,"minor":8,"micro":0},"banner":null,"locals":["enUS"],"currentLocale":"enUS","hostname":"Delphix5110HWv8","sshPublicKey":"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOsrp7Aj6hFQh9yBq7273B+qtPKmCu1B18nPvr08yjt/IZeM4qKk7caxExQS9rpfU8AWoT7e8ESV7NkBmUzOHrHnLsuJtxPqeYoqeMubVxYjJuxlH368sZuYsnB04KM0mi39e15lxVGvxQk9tyMpl7gs7cXRz1k6puncyiczU/axGq7ALHU2uyQoVmlPasuHJbq23d21VAYLuscbtgpZLAFlR8eQH5Xqaa0RT+aQJ6B1ihZ7S0ZN914M2gZHHNYcSGDWZHwUnBGttnxx1ofRcyN4/qwT5iHq5kjApjSaNgSAU0ExqDHiqgTq0wttf5nltCqGMTFR7XY38HiNq++atDroot@Delphix5110HWv8\n","memorySize":8.58107904E9,"platform":"VMware with BIOS date 05/20/2014","uuid":"564d7e1df4cb-f91098fd348d74817683","processors":[{"type":"CPUInfo","speed":2.5E9,"cores":1}],"storageUsed":2.158171648E9,"storageTotal":2.0673724416E10,"installationTime":"2016-07-27T13:28:46.000Z"},"job":null,"action":null}'
$o = ConvertFrom-Json $json
write-output "${nl}System JSON Results: "
$o

#Write-Output "$o"

#
# Parse result object ...
# 
$a = $o.result
write-output "${nl}Parse out result object: "
$a
write-output "${nl}Get result respective values: "
$tmp = $a.type
write-output "type: $tmp"
$tmp = $a.buildTitle
write-output "buildTitle: $tmp"
$tmp = $a.hostname
write-output "hostname: $tmp"

#
# Parse result.buildVersion object ...
#
$a1 = $o.result.buildVersion
write-output "${nl}Get result.buildVersion objects: "
$a1
write-output "${nl}Get result respective values: "
$tmp = $a1.major
write-output "major: $tmp"

#
# Parse result.processors array collection ...
#
$b = $o.result.processors 
write-output "${nl}Get result.processors array collection and converting to objects: "
$b1 = $b | Select-Object
$b1
write-output "${nl}Get result respective values: "
$tmp = $b1.type
write-output "type: $tmp"
$tmp = $b1.speed
write-output "speed: $tmp"
$tmp = $b1.cores
write-output "cores: $tmp"


# 
# Done ...
#
Remove-Variable nl, tmp, a, a1, b, b1, o, json
write-output "Done ..."
exit;

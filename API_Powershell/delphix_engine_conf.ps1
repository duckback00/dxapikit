#
# Delphix Engine Variables ...
#
$BaseURL = "http://172.16.160.195/resources/json/delphix"
$DMUSER = "delphix_admin"
$DMPASS = "delphix"

#
# Application Variables ...
#
$nl = [Environment]::NewLine
$CONTENT_TYPE = "Content-Type: application/json"
$COOKIE = "cookies.txt"
$DELAYTIMESEC=10
$ignore="No"                 # Ignore Exiting when hitting an API Error 
$DT=Get-Date -Format s
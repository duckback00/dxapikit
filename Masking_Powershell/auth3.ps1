#########################################################
## Delphix Masking Parameter Initialization ...

$DMUSER="Alan"           
$DMPASS='Camaro$99' 
$DMURL="http://172.16.160.195/masking/api"     
##$DMURL="https://cp-sm-v00306.fi.com:8443/masking/api"     
$CONTENT_TYPE="Content-Type: application/json"    

#Set-StrictMode -Version 1
Set-StrictMode -Off
#Set-PSDebug -Trace 2
 
echo "Authenticating on ${DMURL}"

$json = @"
{
    \"username\": \"${DMUSER}\",
    \"password\": \"${DMPASS}\"
}
"@

echo "JSON: ${json}"

$results = (C:\Windows\system32\curl.exe -H "${CONTENT_TYPE}" -sX POST "$DMURL/login" -d "${json}")   
echo $results
$o = ConvertFrom-Json $results
$KEY=$o.Authorization
echo "Token: $KEY"

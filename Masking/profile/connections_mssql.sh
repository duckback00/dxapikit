CONN="[
{ 
  \"username\": \"delphixdb\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"MSSQL\",
  \"host\": \"172.16.160.134\",
  \"port\": 1433, 
  \"schemaName\": \"dbo\",
  \"profileSetName\": \"Financial\",
  \"connNo\": 1,
  \"sid\": \"\",
  \"instanceName\": \"MSSQLSERVER\",
  \"databaseName\": \"Vdelphix_demo\",
  \"runMaskingJob\": \"NO\"
},
  {
  \"username\": \"delphixdb\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"MSSQL\",
  \"host\": \"172.16.160.134\",
  \"port\": 1433,
  \"schemaName\": \"dbo\",
  \"profileSetName\": \"HIPAA\",
  \"connNo\": 2,
  \"sid\": \"\",
  \"instanceName\": \"MSSQLSERVER\",
  \"databaseName\": \"Vdelphix_demo\",
  \"runMaskingJob\": \"NO\"
}
]
"
#databaseType,host,port,sid,instanceName,databaseName,schemaName,username,password,jdbc,profileSetName,runMaskingJob,theEnd
#MSSQL,172.16.160.134,1433,,MSSQLSERVER,Vdelphix_demo,dbo,delphixdb,delphixdb,,Financial,NO,theEnd
#MSSQL,172.16.160.134,1433,,MSSQLSERVER,Vdelphix_demo,dbo,delphixdb,delphixdb,,HIPAA,NO,theEnd


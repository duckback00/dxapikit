
CONN="[
{
  \"username\": \"DELPHIXDB\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.129.133\",
  \"port\": 1521,
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"HIPAA\",
  \"connNo\": 1,
  \"sid\": \"VBITT\",
  \"runMaskingJob\": \"NO\"
}
,
{ 
  \"username\": \"DELPHIXDB\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.129.133\",
  \"port\": 1521, 
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"Financial\",
  \"connNo\": 2,
  \"sid\": \"VBITT\",
  \"runMaskingJob\": \"YES\"
}
]
"

#
# Add additional JSON database connection objects if desired ...
# remove previous 5 lines which include this line plus next line
XTMP="
, {
  \"username\": \"DELPHIXDB\",
  \"password\": \"delphixdb\",
  \"databaseType\": \"ORACLE\",
  \"host\": \"172.16.160.133\",
  \"port\": 1521,
  \"schemaName\": \"DELPHIXDB\",
  \"profileSetName\": \"HIPAA\",
  \"connNo\": 3,
  \"sid\": \"VBITT2\",
  \"runMaskingJob\": \"YES\"
}
]
"



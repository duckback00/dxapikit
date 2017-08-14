import requests

USERNAME = 'delphix_admin' # put correct usename here
PASSWORD = 'Delphix_123' # put correct password here

MASKINGURL = 'http://172.16.160.195:8282'

LOGINURL = MASKINGURL + '/dmsuite/login.do'
LOGSURL = MASKINGURL + '/dmsuite/logsReport.do'
DATAURL = MASKINGURL + '/dmsuite/logsReport.do?action=download'

session = requests.session()

req_headers = {
    'Content-Type': 'application/x-www-form-urlencoded'
}

formdata = {
    'userName': USERNAME,
    'password': PASSWORD,
}

# Authenticate
session.post(LOGINURL, data=formdata, headers=req_headers, allow_redirects=False)
session.get(LOGSURL)
r2 = session.get(DATAURL)

print r2.text 

#print "Writing data to python_dmsuite.log file "
## Write to file ...
#f1=open('./python_dmsuite.log', 'w+')
#f1.write(r2.text);



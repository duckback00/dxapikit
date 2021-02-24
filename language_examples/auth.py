#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2017 by Delphix. All rights reserved.
#
# Program Name : auth.py
# Description  : Delphix API Example for Python
# Author       : Unknown 
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) Change values below as required
#
# Usage: python auth.py 
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

DMUSER='admin'
DMPASS='Admin-12'
DELAYTIMESEC=10
BASEURL='http://172.16.129.132/resources/json/delphix'

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

import requests
import json

#
# Request Headers ...
#
req_headers = {
    'Content-Type': 'application/json'
}

#
# Python session, also handles the cookies ...
#
session = requests.session()

#
# Authenticate ...
#
print ("Authenticating URL " + BASEURL + " ... ")
formdata = '{ "type": "APISession", "version": { "type": "APIVersion", "major": 1, "minor": 7, "micro": 0 } }'
r = session.post(BASEURL+'/session', data=formdata, headers=req_headers, allow_redirects=False)
print (r.text)

# 
# Login ...
#
print ("Login ... ")
formdata = '{ "type": "LoginRequest", "username": "' + DMUSER + '", "password": "' + DMPASS + '" }'
r = session.post(BASEURL+'/login', data=formdata, headers=req_headers, allow_redirects=False)
print (r.text)

#
# About ...
# 
print ("About ... ")
r = session.get(BASEURL+'/about')
print (r.text) 

#
# JSON Parsing ...
#
print ("JSON Parsing Examples ...")
j = json.loads(r.text)
print (j['status'])
print (j['result']['buildTitle'])
print (j['result']['apiVersion']['major'])



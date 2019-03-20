#!/usr/bin/perl -w
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
# Program Name : perl_curl.pl
# Description  : Delphix API Example for Perl
# Author       : Alan Bitterman
# Created      : 2017-08-09
# Version      : v1.0.0
#
# Requirements :
#  1.) curl command line libraries
#  2.) Change values below as required
#
# Usage: perl perl_curl.pl
#
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

$BaseURL = "http://172.16.160.195/resources/json/delphix";
$DMUSER = "delphix_admin";
$DMPASS = "delphix";

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

my $cmd = "";
my $results = "";

print "Testing cURL on Perl ...\n\n";

#$results = `curl http://www.google.com`;

##########################################################################
#
# Session ...
#
$cmd = "curl -s -X POST -k --data \@- \"$BaseURL/session\" -c ~/cookies.txt -H \"Content-Type: application/json\" <<EOF 
{ 
  \"type\": \"APISession\"
, \"version\": { \"type\": \"APIVersion\", \"major\": 1, \"minor\": 7, \"micro\": 0 } 
}
EOF
";

#print "cmd> $cmd \n";
$results = `$cmd`;
print "Session Results: $results \n\n";

##########################################################################
#
# Login ...
#
$cmd = "curl -s -X POST -k --data \@- \"http://172.16.160.195/resources/json/delphix/login\" -b ~/cookies.txt -c ~/cookies.txt -H \"Content-Type: application/json\" <<EOF
{
    \"type\": \"LoginRequest\",
    \"username\": \"$DMUSER\",
    \"password\": \"$DMPASS\"
}
EOF
";

#print "cmd> $cmd \n";
$results = `$cmd`;
print "Login Results: $results \n\n";

##########################################################################
#
# Get Environment Info ...
#
$cmd = "curl -s -X GET -k \"http://172.16.160.195/resources/json/delphix/environment\" -b ~/cookies.txt -H \"Content-Type: application/json\"";

#print "cmd> $cmd \n";
$results = `$cmd`;
print "Enviornment Results: $results \n\n";

#
# Add logic ...
# 

#
# The End ...
#
print "Done\n";
exit 0;



<?php
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Copyright (c) 2017 by Delphix. All rights reserved.
//
// Program Name : delphix_curl.php
// Description  : Delphix API Example for PHP
// Author       : Alan Bitterman
// Created      : 2017-08-09
// Version      : v1.0.0
//
// Requirements :
//  1.) curl command line libraries
//  2.) Change values below as required
//
// Usage: php delphix_curl.php 
//
///////////////////////////////////////////////////////////
//                    DELPHIX CORP                       //
// Please make changes to the parameters below as req'd! //
///////////////////////////////////////////////////////////

//
// Variables ...
// 
$BaseURL = "http://172.16.160.195/resources/json/delphix";
$username = "delphix_admin";
$password = "delphix";

///////////////////////////////////////////////////////////
//         NO CHANGES REQUIRED BELOW THIS POINT          //
///////////////////////////////////////////////////////////

// 
// Session ...
//
$data = array("type" => "APISession"
, "version" => array( "type" => "APIVersion", "major" => 1, "minor" => 7, "micro" => 0)
);
//print_r($data);
$data_string = json_encode($data);                                                                                   
echo "Session json> $data_string \n";

$ch = curl_init("$BaseURL/session"); 
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");        // POST   
curl_setopt($ch, CURLOPT_POSTFIELDS, $data_string);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);                                                                      
curl_setopt($ch, CURLOPT_COOKIESESSION, true);          // Use Cookie Session for API Authentication ...
curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookie.txt');
curl_setopt($ch, CURLOPT_HTTPHEADER, array(       
    'Content-Type: application/json',                                                                                
    'Content-Length: ' . strlen($data_string))   
); 
$result = curl_exec($ch);
echo "Session Results> $result \n";

//
// Login ...
//
$data = array(
  "type" => "LoginRequest"
, "username" => "$username"
, "password" => "$password" 
);

//print_r($data);
$data_string = json_encode($data);
echo "Login json> $data_string \n";

curl_setopt($ch, CURLOPT_URL,"$BaseURL/login");
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");         // POST
curl_setopt($ch, CURLOPT_POSTFIELDS, $data_string);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
///curl_setopt($ch, CURLOPT_COOKIESESSION, true);        // use in session only 
curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookie.txt');
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Content-Length: ' . strlen($data_string))
);
$result = curl_exec($ch);
echo "Login Results> $result \n";

/////////////////////////////////////////////////////////////
// 
// Add Logic as Required ...
//


// 
// Delphix Engine About API ...
//
echo "Calling About API ...\n";
curl_setopt($ch, CURLOPT_URL,"$BaseURL/about");
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "GET");          // GET
///curl_setopt($ch, CURLOPT_POSTFIELDS, $data_string);   // using GET, no POST data required ...
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
///curl_setopt($ch, CURLOPT_COOKIESESSION, true);        // use in session only 
curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookie.txt');
curl_setopt($ch, CURLOPT_HTTPHEADER, array( 'Content-Type: application/json' ));
$result = curl_exec($ch);
echo "About Results> $result \n";

echo "Converting json string to a PHP Array \n";
$arr = json_decode($result);
print_r($arr);


/////////////////////////////////////////////////////////////
// 
// The End ...
//
curl_close($ch);            // close curl session (required to keep open for authentication)
?>

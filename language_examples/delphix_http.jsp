<%@ page import="java.io.*,java.util.*,java.net.*" %>
<%
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
// Program Name : delphix_http.jsp
// Description  : Delphix API Example for JSP 
// Author       : Alan Bitterman
// Created      : 2017-08-09
// Version      : v2.0.0 2019-03-20
//
// Requirements :
//  1.) Change values below as required
//
// Usage: http://localhost:8080/[application]/delphix_http.jsp
//
///////////////////////////////////////////////////////////
//                    DELPHIX CORP                       //
// Please make changes to the parameters below as req'd! //
///////////////////////////////////////////////////////////

// 
// Variables ...
//
String url_str = "http://172.16.160.195/resources/json/delphix";
String username = "delphix_admin";
String password = "delphix";
String urlParameters = "";
String endpoint = "";
String cookie = "";
String line = "";
URL endpointURL = null;
HttpURLConnection request1 = null;

///////////////////////////////////////////////////////////
//         NO CHANGES REQUIRED BELOW THIS POINT          //
///////////////////////////////////////////////////////////

// 
// Let's Try ...
//
out.println("Trying ...<br />");
try {

   // 
   // Session ...
   //
   endpoint = (url_str + "/session");
   urlParameters = "{\"type\":\"APISession\",\"version\":{\"type\":\"APIVersion\",\"major\":1,\"minor\":7,\"micro\":0}}";

   endpointURL = new URL(endpoint);
   request1 = (HttpURLConnection)endpointURL.openConnection();
   request1.setRequestProperty("Content-Type", "application/json");
   request1.setRequestProperty("Content-Language", "en-US");
   request1.setUseCaches(false);
   request1.setDoInput(true);
   request1.setDoOutput(true);
   // Post Method ...
   request1.setRequestMethod("POST");
   request1.setRequestProperty("Content-Length", "" + Integer.toString(urlParameters.getBytes().length));
   // Let's r/w as required ...
   BufferedReader rd = null;
   DataOutputStream wr = null;
   StringBuilder resp = null;
   try
   {
     if (urlParameters != null)
     {
       wr = new DataOutputStream(request1.getOutputStream());
       wr.writeBytes(urlParameters);
       wr.flush();
       wr.close();
     }
     else
     {
       request1.connect();
     }
     rd = new BufferedReader(new InputStreamReader(request1.getInputStream()));
     resp = new StringBuilder();
     line = null;
     while ((line = rd.readLine()) != null) {
       resp.append(line + '\n');
     }
   }
   catch (MalformedURLException e)
   {
     System.out.println("Exception: " + e.getMessage());
   }
   catch (ProtocolException e)
   {
     System.out.println("Exception: " + e.getMessage());  
   }
   catch (IOException e)
   {
     System.out.println("Exception: " + e.getMessage());
   }
   catch (Exception e)
   {
     System.out.println("Exception: " + e.getMessage());
     e.printStackTrace();
   }
   finally
   {
     if (rd != null)
     {
       try
       {
         rd.close();
       }
       catch (IOException ex) {}
       rd = null;
     }
     if (wr != null)
     {
       try
       {
         wr.close();
       }
       catch (IOException ex) {}
       wr = null;
     }
   }
   // return resp.toString();
   out.println("session> "+resp.toString()+"<br />" ) ;

   // 
   // Session Cookie ...
   //
   String headerName = null;
   String cookieStr = null;
   for (int i = 1; (headerName = request1.getHeaderFieldKey(i)) != null; i++) {
     if (headerName.equals("Set-Cookie")) {
       cookieStr = request1.getHeaderField(i);
     }
   }
   cookieStr = cookieStr.substring(0, cookieStr.indexOf(";"));
   String cookieName = cookieStr.substring(0, cookieStr.indexOf("="));
   String cookieValue = cookieStr.substring(cookieStr.indexOf("=") + 1, cookieStr.length());
   cookie = cookieName + "=" + cookieValue;

   out.println("cookie> "+ cookie.toString() + "<br />" );

   // 
   // Login ...
   // 
   endpoint = (url_str + "/login");
   urlParameters = ("{\"type\":\"LoginRequest\",\"username\":\""+username+"\"," + "\"password\": \""+password+"\"" +  "}");

   endpointURL = new URL(endpoint);
   request1 = (HttpURLConnection)endpointURL.openConnection();
   request1.setRequestProperty("Content-Type", "application/json");
   request1.setRequestProperty("Content-Language", "en-US");
   request1.setUseCaches(false);
   request1.setDoInput(true);
   request1.setDoOutput(true);
   // Post ...
   request1.setRequestProperty("Content-Length", "" + Integer.toString(urlParameters.getBytes().length));
   request1.setRequestMethod("POST");
   // Cookie Authentication ...
   request1.setRequestProperty("Cookie", cookie);
   if (urlParameters != null)
   {
     wr = new DataOutputStream(request1.getOutputStream());
     wr.writeBytes(urlParameters);
     wr.flush();
     wr.close();
   }
   else
   {
     request1.connect();
   }
   rd = new BufferedReader(new InputStreamReader(request1.getInputStream()));
   resp = new StringBuilder();
   line = null;
   while ((line = rd.readLine()) != null) {
     resp.append(line + '\n');
   }

   out.println("login> "+resp.toString()+"<br />") ;

   //
   // Login Cookie ...
   //
   headerName = null;
   cookieStr = null;
   for (int i = 1; (headerName = request1.getHeaderFieldKey(i)) != null; i++) {
     if (headerName.equals("Set-Cookie")) {
       cookieStr = request1.getHeaderField(i);
     }
   }
   cookieStr = cookieStr.substring(0, cookieStr.indexOf(";"));
   cookieName = cookieStr.substring(0, cookieStr.indexOf("="));
   cookieValue = cookieStr.substring(cookieStr.indexOf("=") + 1, cookieStr.length());
   cookie = cookieName + "=" + cookieValue;

   out.println("cookie> "+ cookie.toString() + "<br />" );

   //
   // System API call ...
   //
   endpoint = (url_str + "/system");
   urlParameters = null;

   endpointURL = new URL(endpoint);
   request1 = (HttpURLConnection)endpointURL.openConnection();
   request1.setRequestProperty("Content-Type", "application/json");
   request1.setRequestProperty("Content-Language", "en-US");
   request1.setUseCaches(false);
   request1.setDoInput(true);
   request1.setDoOutput(true);
   // Get ...
   request1.setRequestMethod("GET");
   //request1.setRequestProperty("Content-Length", "" + Integer.toString(urlParameters.getBytes().length));
   //request1.setRequestMethod("POST");
   request1.setRequestProperty("Cookie", cookie);
   if (urlParameters != null)
   {
      wr = new DataOutputStream(request1.getOutputStream());
      wr.writeBytes(urlParameters);
      wr.flush();
      wr.close();
   } else {
      request1.connect();
   }
   rd = new BufferedReader(new InputStreamReader(request1.getInputStream()));
   resp = new StringBuilder();
   line = null;
   while ((line = rd.readLine()) != null) {
      resp.append(line + '\n');
   }

   // out.println("system> "+resp.toString()+"<br />") ;
   // 
   // Quick and dirty readable JSON string ...
   //
   String str = resp.toString().replaceAll(",",",<br />");;
   out.println("system results> "+str);

}
catch (Exception e0)
{
  System.out.println("Exception: " + e0.getMessage());
  e0.printStackTrace();
}


%>

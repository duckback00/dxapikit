import java.io.*;
import java.net.*;
import java.util.*;
import org.json.simple.*;
import org.json.simple.parser.*;

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
// Copyright (c) 2018 by Delphix. All rights reserved.
//
// Program Name : delphix_sync_simple.java
// Description  : Delphix API Example for Java
// Author       : Alan Bitterman
// Created      : 2018-08-09
// Version      : v2.0.0 2019-03-20
//
// Requirements :
//  1.) Requires json-simple-1.1.jar 
//  2.) Change values below as required
//
// Usage:
//  javac -cp .:json-simple-1.1.jar delphix_sync_simple.java
//  java -cp .:json-simple-1.1.jar delphix_sync_simple 
//
// Notes:
//  1.  Only valid for AppData or Oracle dSource/VDBs as coded
//  2.  This is a simple example and for production use additional
//      code is required, for example;
//      x.) Only search for dSource/VDB name based on type
//      x.) Error trapping logic
//      x.) Delphix Job submission and monitoring
//      x.) etc.
//
///////////////////////////////////////////////////////////
//                    DELPHIX CORP                       //
// Please make changes to the parameters below as req'd! //
///////////////////////////////////////////////////////////

class delphix_sync_simple {
  public static void main(String[] args) throws Exception {

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
    
    //
    // VDB Name to perform Sync (Snapsync or Snapshot) ...
    //
    // Valid Types currently coded are: AppData | Oracle 
    //
    //String type = "AppData";  
    //String name = "VAppData";
    String type = "Oracle";
    String name = "orcl";
    String ref = "";

    ///////////////////////////////////////////////////////////
    //         NO CHANGES REQUIRED BELOW THIS POINT          //
    ///////////////////////////////////////////////////////////

    //
    // Let's Try ...
    //
    System.out.println("Trying ...\n");
    try {

      //
      // Session ...
      //
      endpoint = (url_str + "/session");
      urlParameters = "{\"type\":\"APISession\",\"version\":{\"type\":\"APIVersion\",\"major\":1,\"minor\":7,\"micro\":0}}";

      String session_str[] = getEndPoint("POST", endpoint, cookie, urlParameters);
      System.out.println("session> "+session_str[0]+"\n") ;
      System.out.println("cookie> "+session_str[1]+"\n") ;
      cookie = session_str[1]; 

      //
      // Login ...
      //
      endpoint = (url_str + "/login");
      urlParameters = ("{\"type\":\"LoginRequest\",\"username\":\""+username+"\"," + "\"password\": \""+password+"\"" +  "}");

      endpointURL = new URL(endpoint);

      String login_str[] = getEndPoint("POST", endpoint, cookie, urlParameters);
      System.out.println("login> "+login_str[0]+"\n") ;

      //
      // 5.3 fix backwards compatible
      //
      // After a login, recreate the cookie ...
      //
      System.out.println("cookie> "+login_str[1]+"\n") ;
      cookie = login_str[1];

      //
      // System API call ...
      //
      //endpoint = (url_str + "/system");
      //endpoint = (url_str + "/about"); 
      endpoint = (url_str + "/database");   
      urlParameters = null;
      String str[] = getEndPoint("GET", endpoint, cookie, urlParameters);
      //
      // Quick and dirty readable JSON string ...
      //
      //String str = resp.toString().replaceAll(",",",\n");
      System.out.println("system results> "+str[0]);


      JSONParser parser = new JSONParser();
      //Object obj = parser.parse(new FileReader(sessionFilename));
      Object obj = parser.parse(str[0]);
      JSONObject jsonObject = (JSONObject) obj;

/*
      //
      // Show key value pairs for jsonObject ...
      //
      for(Iterator iterator = jsonObject.keySet().iterator(); iterator.hasNext();) {
         String key = (String) iterator.next();
         System.out.println(key + "---" + jsonObject.get(key));
         //System.out.println("\n");
      }
*/

      //
      // Get result array ...
      //
      JSONArray arr = (JSONArray) jsonObject.get("result");
      Iterator i = arr.iterator();
      while (i.hasNext()) {
        //System.out.println(i.next());
        // 
        // Process objects in array ...
        // 
        JSONObject pobj = (JSONObject) i.next();
        /*
        for(Iterator iterator2 = pobj.keySet().iterator(); iterator2.hasNext();) {
           String key = (String) iterator2.next();
           System.out.println(key + " --- " + pobj.get(key) + "<br />");
        }
        */

        String key = (String) pobj.get("name");
        if (key.equals(name)) {
           //name = (String) pobj.get("name");
           ref = (String) pobj.get("reference");  
        }   

        System.out.println("------------------------");
      }

      System.out.println("Name: "+name+"");
      System.out.println("Reference: "+ref+"");

      //
      // VDB Sync ...
      //
      if (! ref.equals("")) {
         //endpoint = (url_str + "/database/APPDATA_CONTAINER-25/sync");
         endpoint = (url_str + "/database/"+ref+"/sync");
         urlParameters = ("{ \"type\": \""+type+"SyncParameters\" }");
         String sync_str[] = getEndPoint("GET", endpoint, cookie, urlParameters);
         System.out.println("result> "+sync_str[0]);
      }

    } catch (Exception e0) {
      System.out.println("Exception: " + e0.getMessage());
      e0.printStackTrace();
    }

  }

  private static String cut(String str, int l) {
    //String shorter = str.substring(l,str.length()-l+1);
    String shorter = str.substring(l);
    return shorter;
  }

  private static String[] getEndPoint(String request_type, String endpoint, String cookie, String urlParameters) {
    URL endpointURL = null;
    HttpURLConnection request1 = null;
    BufferedReader rd = null;
    DataOutputStream wr = null;
    StringBuilder resp = null;
    resp = new StringBuilder();
    String line = "";

    try {

      endpointURL = new URL(endpoint);
      request1 = (HttpURLConnection)endpointURL.openConnection();
      request1.setRequestProperty("Content-Type", "application/json");
      request1.setRequestProperty("Content-Language", "en-US");
      request1.setUseCaches(false);
      request1.setDoInput(true);
      request1.setDoOutput(true);
      // Get ...
      if (request_type.equals("GET")) {
         request1.setRequestMethod("GET");
      } else {
         request1.setRequestProperty("Content-Length", "" + Integer.toString(urlParameters.getBytes().length));
         request1.setRequestMethod("POST");
      } 
      if (! cookie.equals("")) {
         request1.setRequestProperty("Cookie", cookie);
      }
      if (urlParameters != null) {
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

    } catch (Exception e0) {
      System.out.println("Exception: " + e0.getMessage());
      e0.printStackTrace();
    } finally {
      if (rd != null) {
        try {
          rd.close();
        } catch (IOException ex) {}
        rd = null;
      }
      if (wr != null) {
        try {
          wr.close();
        } catch (IOException ex) {}
        wr = null;
      }
    }

    // 5.3 fix for setting cookie after login, backwards compatible ...
    if (endpoint.endsWith("login")) {
       cookie = "";
    }

    //
    // Session Cookie ...
    //
    if (cookie.equals("")) {
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
    }
    return new String[] {resp.toString(), cookie};
  }

}

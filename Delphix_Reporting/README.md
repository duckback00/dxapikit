# Delphix Reporting APIs and Sample Reports

<table>

  <tr>
   <th align="center" colspan=2>Delphix Reporting APIs</th>
  </tr>
  
  <tr>
   <th align="left">Filename</th>
   <th align="left">Description</th>
  </tr>
  
  <tr>
   <td>dr_api_examples.sh </td>
   <td align="left">One example with all the API calls</td>
  </tr>
  
  <tr>
    <td colspan=2 style="font-size:10px;">
Edit the file to change the configuration values prior to running.

Includes authentication, listing reports, shows specified report name data, adding delphix engines, listing delphix engines, removing delphix engines and logging out 

<ul>
  <li>/api/login</li>
  <li>/api/list_engines</li>
  <li>/api/add_engine?hostname=&lt;de-hostname&gt;&user=&lt;de-user&gt;&password=&lt;de-password&gt;</li>
  <li>/api/remove_engine?hostname=&lt;de-hostname&gt;</li>
  <li>/api/list_reports</li>
  <li>/api/get_report?report=&lt;reportId&gt;</li>
  <li>/api/logout</li>
</ul>
  </td>
  </tr>
  
  <tr>
   <td>dr_vdb.sh </td>
   <td align="left">Consolidated VDB Report for VDB and ENGINE name</td>
  </tr>
  
  <tr>
   <td>dr_dump_all.sh </td>
   <td align="left" width="50%">Dump All Report result collections into one JSON file</td>
  </tr>
 
 </table>
 
 <hr color=teal size=3 />
 
 <table width="100%">

  <tr>
   <th align="center" colspan=2>Delphix Reporting Custom/User Reports</th>
  </tr>
  
  <tr>
   <th align="left">Filename</th>
   <th align="left">Description</th>
  </tr>
  
  <tr>
   <td>recent_db_sync_jobs.js</td>
   <td align="left">Show Recent DB_SYNC Jobs (last 2k)</td>
  </tr>

  <tr>
   <td>recent_db_rollback_jobs.js</td>
   <td align="left">Show Recent DB_ROLLBACK Jobs (last 2k)</td>
  </tr>
  
  <tr>
   <td>recent_db_refresh_jobs.js</td>
   <td align="left">Show Recent DB_REFRESH Jobs (last 2k)</td>
  </tr>
  
  <tr>
   <td>recent_actions.js</td>
   <td align="left">Show Recent Actions (Warning: last 50k)</td>
  </tr>
  
  </table>
  
*** End of Document ***

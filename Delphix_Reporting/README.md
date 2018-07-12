# Delphix Reporting APIs

<table>
  <tr>
   <td align=right>One example with all the API calls</td><td>Filename: dr_api_examples.sh </td>
  </tr>
  <tr>
    <td colspan=2>
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
   <td align=right>Consolidated VDB Report for VDB and ENGINE name</td><td>Filename: dr_vdb.sh </td>
  </tr>
  <tr>
   <td align=right width="50%">Dump All Report result collections into one JSON file</td><td>Filename: dr_dump_all.sh </td>
  </tr>
*** End of Document ***

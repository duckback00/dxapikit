README.txt
v1.2.2

** So you want to work with the Delphix APIs? **

Unix/Linux/Mac Shell Scripts

Disclaimer: As always, these scripts are provided "as-is" and the end user is responsible
for the application and usage of these scripts within their environment. Test, verify, 
re-test, and re-verify prior to using any code into production. 

These scripts are basic examples and some require manual editing of the files for configuring 
the parameter values for the respective environment and operations. 

First, update the    delphix_engine.conf   file for your Delphix Engine connection information!

# 
# Delphix Engine Config File ...
#
# Replace Delphix Engine IP Address, replace 127.0.0.1 with your DE IP Address 
# Replace Account Credentials 
#

vi delphix_engine.conf
...
DMIP="172.16.160.195"             # include port if required, "172.16.160.195:80" or :443
DMUSER=delphix_admin
DMPASS=delphix
...
[save & exit]



Appendix
--------
Quick Start - Sample Scripts

The Unix/Linux/Mac shell scripts required the jq command line parser and curl command line libraries.

NOTE: The exact versions for both curl and jq are typically not important since the examples use the basic functionality which has been in the products for a while now.

For Unix/Linux/Mac environments, verify that jq is installed.

$ which jq
/usr/local/bin/jq

$ jq --version
jq version 1.3   (Linux)
jq-1.4           (Mac)

$ which curl
/usr/bin/curl

$ curl --version
curl 7.19.7 (x86_64-redhat-linux-gnu) libcurl/7.19.7 NSS/3.19.1 Basic ECC zlib/1.2.3 libidn/1.18 libssh2/1.4.2  (Linux)
curl 7.43.0 (x86_64-apple-darwin14.0) libcurl/7.43.0 SecureTransport zlib/1.2.5  (Mac)


Sample Scripts
--------------

Linux Included Config Scripts
   Delphix Engine Configuration Parameter Values   Filename: delphix_engine.conf
   jq JSON Parsing Functions in Examples           Filename: jqJSON_subroutines.sh

Authentication
   Linux Shell Script Authentication   		   Filename: linux_shell_authentication.sh

Delphix Engine
   Delphix Engine User Timeout Value 		   Filename: user_timeout_jq.sh
        Concatenate DE Objects into single JSON string  
						   Filename: delphix_objects_json.sh
           Usage: . ./delphix_objects_json.sh
                  echo $JSON

Delphix dSource/VDB Operations
   VDB Init (start|stop|enable|disable|delete) 	   Filename: vdb_init.sh
   VDB Operations (sync|refresh|rollback)          Filename: vdb_operations.sh

Delphix Groups
        Group Operations (list|create|delete)      Filename: group_operations.sh

Oracle Database Template (Init Parameters)
   List, Create, Update and Delete Oracle Template Parameters   
						   Filename: vdb_oracle_template.sh
   Sample Oracle Init File			   Filename: 200M

Linux / Oracle Database
   Link/Ingest an Oracle dSource                   Filename: link_oracle_jq.sh
   Provision an Oracle VDB                         Filename: provision_oracle_jq.sh
   Provision another Oracle VDB                    Filename: provision_oracle_child_jq.sh
   Delete a dSource or Virtural Database           Filename: delete_database_oracle_jq.sh
   Provision an Oracle VDB Interactive or Command Line Parameters
						   Filename: provision_oracle_i.sh

Linux / ASE Database
   VDB Init (start|stop|enable|disable|delete)     Filename: vdb_ase_init.sh
   VDB Operations (sync|refresh|rollback)          Filename: vdb_ase_operations.sh
   Link/Ingest an ASE dSource                      Filename: link_ase_jq.sh
   Provision an ASE VDB                            Filename: provision_ase_jq.sh

Linux / SQL Server Database
   Link/Ingest a SQL Server dSource                Filename: link_sqlserver_jq.sh
   Provision a SQL Server VDB                      Filename: provision_sqlserver_jq.sh
	
Timeflows
   VDB Timeflow Object Information /Details	   Filename: flows.sh
   Find Timeflow Object by Timestamp               Filename: timestamp.sh
   Rollback VDB to Timestamp			   Filename: vdb_rollback_timestamp.sh
   Rollback VDB to Snapshot			   Filename: vdb_rollback_snapshot.sh
   Rollback VDB to SCN (location)		   Filename: vdb_rollback_scn.sh
   Refresh VDB to Timestamp			   Filename: vdb_refresh_timestamp.sh
   Refresh VDB to Snapshot			   Filename: vdb_refresh_snapshot.sh
   Refresh VDB to SCN (location)		   Filename: vdb_refresh_scn.sh

Jetstream
   Get a JSON list of Jetstream Objects		   Filename: . ./jetstream_objects_json.sh
	
Jetstream - Bookmarks	
   Create a new Bookmark from Latest		   Filename: jetstream_bookmark_create_from_latest_jq.sh
   Create a new Bookmark from Timestamp		   Filename: jetstream_bookmark_create_from_timestamp_jq.sh
   Delete a Bookmark 				   Filename: jetstream_bookmark_delete_jq.sh

Jetstream - Branches
   Create a Branch from a Bookmark		   Filename: jetstream_branch_create_from_bookmark_jq.sh
   Create a Branch from the Latest Timestamp	   Filename: jetstream_branch_create_from_latest_jq.sh
   Create a Branch from a provided Timestamp 	   Filename: jetstream_branch_create_from_timestamp_jq.sh
   Active/Delete a Branch			   Filename: jetstream_branch_operations_jq.sh

Jetstream - Containers
   Create a new Container 			   Filename: jetstream_container_create_jq.sh
   Delete a Container			 	   Filename: jetstream_container_delete_jq.sh
   Refresh a Container from Template Source	   Filename: jetstream_container_refresh_jq.sh
   Reset a Container to last Event		   Filename: jetstream_container_reset_jq.sh
   Restore a Container to a Bookmark		   Filename: jetstream_container_restore_to_bookmark_jq.sh
   Restore a Container to a provided Timestamp	   Filename: jetstream_container_restore_to_timestamp_jq.sh
   Start/Stop a Jetstream Container 		   Filename: jetstream_container_stop_start_jq.sh
   Get Active Branch at Timestamp		Filename: jetstream_container_active_branch_at_timestamp.sh
   List Users per Jetstream Container              Filename: jetstream_container_users_jq.sh

Jetstream - Templates	
   Create a new Jetstream Template  		   Filename: jetstream_template_create_jq.sh
   Delete a Jetstream Template  		   Filename: jetstream_template_delete_jq.sh           

Snapshots
   Display Snapshot Details; Database, Snapshot, Size, Timeflow Dependency, VDB Dependency, Retention 
   with option to delete non-dependent snapshots, change retention to keep_forever or keep until # days	
						   Filename: snapshot_details.sh	
	
Jobs
   Display list of Delphix Engine Jobs		   Filename: jobs.sh


*** End of README.txt ***

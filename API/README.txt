#dxapikit

## So you want to work with the Delphix APIs?

Disclaimer: As always, these scripts are provided "as-is" and the end user is responsible
for the application and usage of these scripts within their environment. Test, verify, 
re-test, and re-verify prior to using any code into production. 

These scripts are basic examples and require manual editing of the files for configuring 
the parameter values for the respective environment and operations. 


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

Quick Start - Sample Scripts

Note: Almost all the Unix/Linux/Mac shell scripts required the jq command line parser.

For Unix/Linux/Mac environments, verify that jq is installed.
$ which jq
/usr/local/bin/jq

$ jq --version
jq-1.4


First, update the    delphix_engine.conf   file for your Delphix Engine connection information!

Linux Included Config Scripts
        Delphix Engine Configuration Parameter Values	Filename: delphix_engine.conf
        jq JSON Parsing Functions in Examples           Filename: jqJSON_subroutines.sh

Authentication
	Linux Shell Script Authentication   		Filename: linux_shell_authentication.sh

Delphix Engine
	Delphix Engine User Timeout Value 		Filename: user_timeout_jq.sh
        Concatenate DE Objects into single JSON string  Filename: delphix_objects_json.sh
           Usage: . ./delphix_objects_json.sh
                  echo $JSON

Delphix dSource/VDB Operations
	VDB Init (start|stop|enable|disable|delete) 	Filename: vdb_init.sh
        VDB Operations (sync|refresh|rollback)          Filename: vdb_operations.sh

Delphix Groups
        Group Operations (create|delete) 		Filename: group_operations.sh

Linux / Oracle Database
        Link/Ingest an Oracle dSource                   Filename: link_oracle_jq.sh
        Provision an Oracle VDB                         Filename: provision_oracle_jq.sh
        Provision another Oracle VDB                    Filename: provision_oracle_child_jq.sh
        Delete a dSource or Virtural Database           Filename: delete_database_oracle_jq.sh

Linux / ASE Database
        VDB Init (start|stop|enable|disable|delete)     Filename: vdb_ase_init.sh
        VDB Operations (sync|refresh|rollback)          Filename: vdb_ase_operations.sh
        Link/Ingest an ASE dSource                      Filename: link_ase_jq.sh
        Provision an ASE VDB                            Filename: provision_ase_jq.sh

Linux / SQL Server Database
        Link/Ingest a SQL Server dSource                Filename: link_sqlserver.sh
        Provision a SQL Server VDB                      Filename: provision_sqlserver.sh
	
Timeflows
	VDB Timeflow Object Information /Details	Filename: flows.sh
        Find Timeflow Object by Timestamp               Filename: timestamp.sh
	Rollback VDB to Timestamp			Filename: vdb_rollback_timestamp.sh
	Rollback VDB to Snapshot			Filename: vdb_rollback_snapshot.sh
	Rollback VDB to SCN (location)			Filename: vdb_rollback_scn.sh
	Refresh VDB to Timestamp			Filename: vdb_refresh_timestamp.sh
	Refresh VDB to Snapshot				Filename: vdb_refresh_snapshot.sh
	Refresh VDB to SCN (location)			Filename: vdb_refresh_scn.sh

Jetstream
	Create a new Jetstream Template 		Filename: jetstream_template.sh
	Create an Jetstream Container in a Template 	Filename: jetstream_container.sh
	Create a Bookmark within a Branch		Filename: jetstream_bookmark.sh 
	Refresh a Container from Template Source 	Filename: jetstream_refresh.sh
	
Jobs
	Display list of Delphix Engine Jobs		Filename: jobs.sh


*** WIP contact me for details or updates ***

Hooks
Filename: get_hook_template.sh
Filename: get_source_hooks.sh
Filename: read_hook.sh


*** End of README.txt ***

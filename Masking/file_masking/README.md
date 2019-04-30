## README.md

API example for masking a CSV delimited file: <br />
<ul>
<li>Masking File Pre-Processing ...</li>
<ul>
<li>Create Header File if not provided, assuming first line in file is header ...</li>
</ul>
<li>Session Login/Authentication ...</li>
<li>Get Environment Id and Application Name ...</li>
<li>Get Connector Id ...</li>
<li>Create File Format ...</li>
<li>Create Rule Set ...</li>
<li>Source Data File Relationships ...</li>
<li>Process File Fields ...</li>
<li>Update Inventory File Field Values for Masking ...</li>
<ul>
<li>Update (POST) file-field-metadata, i.e. add domain and algorithm ...</li>
</ul>
<li>Create Masking Job ...</li>
<li>Execute Masking Job ...</li>
<li>Monitor Job Status ...</li>
<li>[Optional] Masking Clean Up ...</li>
<li>Masked File Post-Processing ...</li>
<ul>
	<li>Add Header Line back into Source File ... </li>
</ul>
<li>Done</li>
</ul>

# Modify agile_delim.sh for static parameters 
# Modify masking_engine.conf for authentication information
#
# Requires:
# x.) Existing Environment Name
# x.) Existing File Connector Name
#
# Arguments:
#
#./agile_delim.sh 
#     [data_file] 					# 1 Source Delimited File
#         [header_file] 				# 2 or "" Optional Column Header Names one per line
#            [algorithm_file]				# 3 Column Header Name, Domain Name and Algorithm mapping file
#               [environment_name]			# 4 Existing Masking Environment Name
#                  [file_connector]			# 5 Existing Masking Connector Name to this path
#                     [DELIMITED, EXCEL, FIXED_WIDTH]   # 6 File Type: DELIMITED only valid type for this script
#                        [endOfRecord] 			# 7 linux only supported at this time (hard coded) 
#                           [delimChar] 		# 8 Source File delimiter: comma
#                              [textEnclosure] 		# 9 Source File text enclosure: double quote
#                                  [YES, NO]		#10 Clean Up: YES or NO
#
# Usage:  Delimited File with Header Column Names in first line ...  
# ./agile_delim.sh bmobitth.csv "" delim_domains.txt "file_env" "file_delim_conn" "DELIMITED" "linux" "," "\"" "YES"
#
# Usage:  Delimited File Data ONLY with seperate Column Names file ...
# ./agile_delim.sh bmobitt.csv delim_fields.txt delim_domains.txt "file_env" "file_delim_conn" "DELIMITED" "linux" "," "\"" "YES"
#


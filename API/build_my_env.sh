
#
# Create Groups in DE ...
#
./group_operations.sh create "Oracle_Source"
./group_operations.sh create "Oracle_Target"

./group_operations.sh create "Windows_Source"
./group_operations.sh create "Windows_Target"

./group_operations.sh delete Untitled

#
# Verify Oracle Environment is Up and listener/database are running ...
#
./create_oracle_target_env.sh

#
# Verify Windows Environment is Up and SQL Server is running ...
#
#./create_window_target_env.sh
#. .\create_window_target_env.ps1


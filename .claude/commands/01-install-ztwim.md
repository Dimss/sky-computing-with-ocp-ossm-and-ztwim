## Sky Computing Blog Post - Install Zero-Trust Workload Identity Manager (ZTWIM)  
`* All scripts must be executed relatively to working directory`
* Execute scripts from `./01` directory in order based on their numeric prefixes and execute the scripts one by one
* Print exit code for each executed script, if code is 0 add green check mark symbol, otherwise add red error symbol 
* Verify that each script exit with 0 status code, otherwise stop the execution. 
* Skip `01/01-define-exports.sh` script 
* Only for the last script `01/70-verify-ztwim-installation.sh` print the script STDOUT output to console
* Execution summary: Print summery in 3 column table: green check emoji with script name, execution status - success or failure, exit code - numeric exit code

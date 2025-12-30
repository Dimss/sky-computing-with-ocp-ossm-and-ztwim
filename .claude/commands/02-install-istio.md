## Sky Computing Blog Post - Install OSSM (Istio) 
* All scripts must be executed relatively to working directory 
* Execute scripts from `./02` directory in order based on their numeric prefixes and execute the scripts one by one
* Print exit code for each executed script, if code is 0 add green check mark symbol, otherwise add red error symbol  
* If a script returned none 0 code, immediately interrupt command execution and print the error to the console   
* Skip `02/01-define-exports.sh` script 
* Only for the last script `01/40-verify-ossm-installation.sh` print the script STDOUT output to console using following format, each line that starts with `Issuer:` or `Subject:` should be prefixed with OK Hand emoji
* Execution summary: Print summery in 3 column table: green check emoji with script name, execution status - success or failure, exit code - numeric exit code

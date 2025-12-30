## Sky Computing Blog Post - Connecting external service to the mesh
* All scripts must be executed relatively to working directory
* Execute scripts from `./05` directory in order based on their numeric prefixes and execute the scripts one by one
* If a script returned none 0 code, immediately interrupt command execution and print the error to the console
* Do not print `Unable to use a TTY - input is not a terminal or the right kind of file` if appears. 
* Print exit code for each executed script. If code is 0 add green check mark symbol, otherwise add red error symbol
* Skip `./05/01-define-exports.sh` script
* Execution summary: Print summery in 3 column table: green check emoji with script name, execution status - success or failure, exit code - numeric exit code 

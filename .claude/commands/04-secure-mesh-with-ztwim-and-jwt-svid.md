## Sky Computing Blog Post - Securing the Mesh with SPIFFE X.509 and JWT SVIDs
* Print the ascii illustration
+-------------------------------------------------------------------------------------------+
| KUBERNETES NODE                                                                           |
|                                                                                           |
|   +=======================================+   +=======================================+   |
|   | POD A (Client "frontend")             |   | POD B (Server "backend")              |   |
|   |                                       |   |                                       |   |
|   |  +-------------+                      |   |                      +-------------+  |   |
|   |  | Application |                      |   |                      | Application |  |   |
|   |  | Workload A  |                      |   |                      | Workload B  |  |   |
|   |  +------+------+                      |   |                      +------+------+  |   |
|   |         | (1) Plaintext HTTP          |   |   (5) Plaintext HTTP        ^         |   |
|   |         | (No tokens yet)             |   |   (Authorized request)      |         |   |
|   |         v                             |   |                             |         |   |
|   |  +------+------+                      |   |                      +------+------+  |   |
|   |  | Istio       |                      |   |                      | Istio       |  |   |
|   |  | Sidecar     |                      |   |                      | Sidecar     |  |   |
|   |  | (Envoy)     |                      |   |                      | (Envoy)     |  |   |
|   |  +---.-----.---+                      |   |                      +---.-----.---+  |   |
|   |      .     .                          |   |                          .     .      |   |
|   +======:=====:==========================+   +==========================:=====:======+   |
|          .     .                                                         .     .          |
|          .     . (2) Sidecar A connects to Sidecar B via mTLS.           .     .          |
|          .     .     Uses X.509 SVIDs to establish the encrypted tunnel. .     .          |
|          .     .                                                         .     .          |
|          .   +=============================================================+   .          |
|          .   ||  (3) Encrypted mTLS Tunnel established using X.509 SVIDs  ||   .          |
|          .   ||                                                           ||   .          |
|          .   ||   +---------------------------------------------------+   ||   .          |
|          .   ||   | PAYLOAD INSIDE TUNNEL:                            |   ||   .          |
|          .   ||   | HTTP GET /data                                    |   ||   .          |
|          .   ||   | Authorization: Bearer <JWT SVID>                  |   ||   .          |
|          .   ||   +---------------------------------------------------+   ||   .          |
|          .   ||                                                           ||   .          |
|          .   || (4) Sidecar B receives payload, validates X.509 of peer,  ||   .          |
|          .   ||     then extracts & validates the JWT Bearer token.       ||   .          |
|          .   +=============================================================+   .          |
|          .                                                                     .          |
|          . (Identity Bootstrapping Phase)                                      .          |
|          .......................................................................          |
|          .                                                                     .          |
|          v                                                                     v          |
|  +-------------------------------------------------------------------------------------+  |
|  | SPIRE AGENT (Node Daemon)                                                           |  |
|  |                                                                                     |  |
|  | -> Attests workloads based on K8s PID/Cgroup.                                       |  |
|  | -> Issues BOTH:                                                                     |  |
|  |    1. X.509 SVID (Certificate for mTLS)                                             |  |
|  |    2. JWT SVID   (Bearer Token for Request Auth)                                    |  |
|  +-------------------------------------------------------------------------------------+  |
+-------------------------------------------------------------------------------------------+
* All scripts must be executed relatively to working directory
* Execute scripts from `./04` directory in order based on their numeric prefixes and execute the scripts one by one
* Do not print `Unable to use a TTY - input is not a terminal or the right kind of file` if appears. 
* Print exit code for each executed script, if code is 0 add green check mark symbol, otherwise add red error symbol  
* If a script returned none 0 code, except `./04/20-make-http-call.sh` immediately interrupt command execution and print the error to the console
* For `./04/20-make-http-call.sh` script expect to exit with nono 0 code, this is OK, continue the execution. 
* Skip `02/01-define-exports.sh` script
* Highlight the output of `./03/60-make-http-call.sh` script. If the output include `200` prefix the output line with OK Hand emoji, otherwise prefix with error emoji
* Execution summary: Print summery in 3 column table: green check emoji with script name, execution status - success or failure, exit code - numeric exit code 

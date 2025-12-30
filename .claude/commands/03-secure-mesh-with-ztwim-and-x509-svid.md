## Sky Computing Blog Post - Securing the Mesh with SPIFFE X.509 
* Print the ascii illustration 
+------------------------------------------------------------------------------------+
|  KUBERNETES NODE (Physical/VM Host)                                                |
|                                                                                    |
|    +=====================================+   +===================================+ |
|    |  POD A (Namespace X)                |   |  POD B (Namespace Y)              | |
|    |                                     |   |                                   | |
|    |  +------------+                     |   |                     +-----------+ | |
|    |  | Application|                     |   |                     |Application| | |
|    |  | Workload A |                     |   |                     |Workload B | | |
|    |  +-----+------+                     |   |                     +------+----+ | |
|    |        | (1) Plaintext              |   |            (4) Plaintext |        | |
|    |        | localhost traffic          |   |        localhost traffic |        | |
|    |        v                            |   |                          v        | |
|    |  +-----+------+                     |   |                     +------+---+  | |
|    |  | Istio      | (2) Encrypted mTLS  |   |  (2) Encrypted mTLS | Istio    |  | |
|    |  | Sidecar    |==============================================>| Sidecar  |  | |
|    |  | (Envoy)    |<==============================================| (Envoy)  |  | |
|    |  +--.---.-----+ (X509 SVID secured) |   | (X509 SVID secured) +---.---.--+  | |
|    +=====:===:===========================+   +=========================:===:=====+ |
|          :   :                                                         :   :       |
|          :   : (3) Fetch SVIDs (x509/JWT) via Workload API (UDS)       :   :       |
|          :   :.........................................................:   :       |
|          :                                                                 :       |
|          v                                                                 v       |
|       +---------------------------------------------------------------------+      |
|       | SPIRE AGENT (Node Daemon)                                           |      |
|       | - Attests workload based on K8s selectors.                          |      |
|       | - Mints SVIDs signed by the SPIRE Server CA.                        |      |
|       +---------------------------------------------------------------------+      |
|                                                                                    |
+------------------------------------------------------------------------------------+
* All scripts must be executed relatively to working directory
* Execute scripts from `./03` directory in order based on their numeric prefixes and execute the scripts one by one
* Do not print `Unable to use a TTY - input is not a terminal or the right kind of file` if appears. 
* Print exit code for each executed script, if code is 0 add green check mark symbol, otherwise add red error symbol  
* If a script returned none 0 code, immediately interrupt command execution and print the error to the console   
* Skip `02/01-define-exports.sh` script 
* Highlight the output of `./03/40-make-http-call.sh` script. If the output include `200` prefix the output line with OK Hand emoji, otherwise prefix with error emoji
* Highlight the output of `./03/60-make-http-call.sh` script. If the output include `200` prefix the output line with OK Hand emoji, otherwise prefix with error emoji
* Execution summary: Print summery in 3 column table: green check emoji with script name, execution status - success or failure, exit code - numeric exit code


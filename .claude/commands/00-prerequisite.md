## Sky Computing Blog Post - Prerequisites

## Command Behavior
This command checks prerequisites and reports results ONLY. Do not suggest next steps or additional actions after completion.

## Checks to Perform
1. Verify OpenShift cli binary installed
2. Verify OpenShift version is at least 4.20
3. Verify `jq` binary installed
4. Verify `openssl` binary installed
5. Verify `istioctl` binary installed
6. Verify admin level access to the OpenShift cluster 
7. Verify `podman` binary installed
8. Verify `aws cli` binary installed


Output Requirements

- Present results in clear format
- End with "Prerequisite check complete."
- Do NOT suggest remediation steps
- Do NOT ask questions about results
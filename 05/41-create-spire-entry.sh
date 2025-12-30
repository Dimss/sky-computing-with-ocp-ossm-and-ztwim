source "$(dirname "$0")/01-define-exports.sh"


oc exec spire-server-0 \
 -c spire-server \
 -n "${ZTWIM_NS}" \
 -- /bin/sh -c "/spire-server \
                   entry show \
                   -spiffeID ${WORKLOAD_SPIFFE_ID} >/dev/null 2>&1 \
                || /spire-server entry create \
                   -parentID ${AGENT_SPIFFE_ID} \
                   -spiffeID ${WORKLOAD_SPIFFE_ID} \
                   -selector ${WORKLOAD_SPIFFE_SELECTOR}"




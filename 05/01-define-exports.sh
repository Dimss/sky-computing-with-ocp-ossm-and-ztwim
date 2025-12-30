source "$(dirname "$0")/../01/01-define-exports.sh"
source "$(dirname "$0")/../02/01-define-exports.sh"
source "$(dirname "$0")/../03/01-define-exports.sh"

export CA_CN="Sky Computing Lab"
export CN_NODE_1="mesh-node-1"
export CERTS_DIR="$(dirname "$0")/data"
export LEGACY_DB_SRV="legacy-db-srv1"
export NEW_ATTESTOR='{"x509pop": {"plugin_data": {"ca_bundle_path": "/tmp/x509pop-ca/ca.crt.pem","agent_path_template":"/x509pop/cn/{{ .Subject.CommonName }}"}}}'
export SPIRE_SERVER_DOMAIN="spire-server.$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
export AGENT_SPIFFE_ID="spiffe://${TRUST_DOMAIN}/spire/agent/x509pop/cn/${CN_NODE_1}"
export WORKLOAD_SPIFFE_ID="spiffe://sky.computing.ocp.one/legacy-db-srv"
export WORKLOAD_SPIFFE_SELECTOR="unix:uid:101"


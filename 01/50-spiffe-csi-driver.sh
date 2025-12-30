source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpiffeCSIDriver
metadata:
  name: cluster
spec:
  agentSocketPath: '/run/spire/agent-sockets'
  pluginName: "csi.spiffe.io"
EOF

until oc get daemonset/spire-spiffe-csi-driver -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done

kubectl rollout status daemonset/spire-spiffe-csi-driver -n "${ZTWIM_NS}" --timeout=300s

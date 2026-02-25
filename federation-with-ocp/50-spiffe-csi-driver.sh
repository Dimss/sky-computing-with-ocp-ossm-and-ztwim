source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

cat <<EOF | oc apply --kubeconfig "${kubeconfig}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpiffeCSIDriver
metadata:
  name: cluster
spec:
  agentSocketPath: '/run/spire/agent-sockets'
  pluginName: "csi.spiffe.io"
EOF

until oc get daemonset/spire-spiffe-csi-driver --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done

oc rollout status daemonset/spire-spiffe-csi-driver --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" --timeout=300s

done


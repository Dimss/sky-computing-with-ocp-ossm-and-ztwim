source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
cat <<EOF | oc apply --kubeconfig "${kubeconfig}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireAgent
metadata:
  name: cluster
spec:
  socketPath: "/run/spire/agent-sockets"
  logLevel: "info"
  logFormat: "text"
  nodeAttestor:
    k8sPSATEnabled: "true"
  workloadAttestors:
    k8sEnabled: "true"
    workloadAttestorsVerification:
      type: "auto"
      hostCertBasePath: "/etc/kubernetes"
      hostCertFileName: "kubelet-ca.crt"
    disableContainerSelectors: "false"
    useNewContainerLocator: "true"
EOF

until oc get daemonset/spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done

oc rollout status daemonset/spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" --timeout=300s

done

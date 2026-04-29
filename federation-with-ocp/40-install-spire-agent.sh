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

# Patch spire-agent configmap to add SDS configuration
for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
  # Get current agent.conf
  AGENT_CONF=$(oc get configmap spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" -o jsonpath='{.data.agent\.conf}')

  # Check if SDS configuration already exists
  if echo "${AGENT_CONF}" | grep -q '"sds"'; then
    echo "SDS configuration already exists in spire-agent configmap, skipping patch"
    continue
  fi

  # Add SDS configuration to agent section using jq
  PATCHED_CONF=$(echo "${AGENT_CONF}" | jq '.agent.sds = {
    "default_svid_name": "default",
    "default_bundle_name": "null",
    "default_all_bundles_name": "ROOTCA"
  }')

  # Create patch payload
  oc patch configmap spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" --type merge -p "{\"data\":{\"agent.conf\":$(echo "${PATCHED_CONF}" | jq -Rs .)}}"

  # Restart spire-agent daemonset to pick up new config
  oc rollout restart daemonset/spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}"
  oc rollout status daemonset/spire-agent --kubeconfig "${kubeconfig}" -n "${ZTWIM_NS}" --timeout=300s
done
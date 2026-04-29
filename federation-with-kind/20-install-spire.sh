source "$(dirname "$0")/01-define-exports.sh"

helm upgrade --install \
   -n spire-server spire-crds \
   spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ \
   --create-namespace \
   --kubeconfig="${CLUSTER_A_KUBECONFIG}"

helm upgrade --install \
   -n spire-server spire spire \
    --repo https://spiffe.github.io/helm-charts-hardened/ \
    --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
    --set global.spire.trustDomain="${CLUSTER_A}" \
    --set spire-server.federation.enabled=true \
    --set spire-server.service.type=LoadBalancer \
    --set "spire-server.controllerManager.identities.clusterSPIFFEIDs.default.federatesWith={${CLUSTER_B}}" \
    --set spire-server.controllerManager.identities.clusterSPIFFEIDs.default.autoPopulateDNSNames=true \
    --set spire-agent.sds.enabled=true \
    --set spire-agent.sds.defaultBundleName="\"null\"" \
    --set spire-agent.sds.defaultAllBundlesName="ROOTCA" \
    --set persistence.size=3Gi

until oc get daemonset/spire-agent --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n spire-server &> /dev/null; do sleep 3; done
oc rollout status daemonset/spire-agent --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n spire-server --timeout=300s

helm upgrade --install \
   -n spire-server spire-crds \
   spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ \
   --create-namespace \
   --kubeconfig="${CLUSTER_B_KUBECONFIG}"

helm upgrade --install \
   -n spire-server spire spire \
    --repo https://spiffe.github.io/helm-charts-hardened/ \
    --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
    --set global.spire.trustDomain="${CLUSTER_B}" \
    --set spire-server.federation.enabled=true \
    --set spire-server.service.type=LoadBalancer \
    --set "spire-server.controllerManager.identities.clusterSPIFFEIDs.default.federatesWith={${CLUSTER_A}}" \
    --set spire-server.controllerManager.identities.clusterSPIFFEIDs.default.autoPopulateDNSNames=true \
    --set spire-agent.sds.enabled=true \
    --set spire-agent.sds.defaultBundleName="\"null\"" \
    --set spire-agent.sds.defaultAllBundlesName="ROOTCA" \
    --set persistence.size=3Gi

until oc get daemonset/spire-agent --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n spire-server &> /dev/null; do sleep 3; done
oc rollout status daemonset/spire-agent --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n spire-server --timeout=300s

#
## Patch spire-agent configmap to add SDS configuration
#for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
#  # Get current agent.conf
#  AGENT_CONF=$(oc get configmap spire-agent --kubeconfig "${kubeconfig}" -n spire-server -o jsonpath='{.data.agent\.conf}')
#
#  # Check if SDS configuration already exists
#  if echo "${AGENT_CONF}" | grep -q '"sds"'; then
#    echo "SDS configuration already exists in spire-agent configmap, skipping patch"
#    continue
#  fi
#
#  # Add SDS configuration to agent section using jq
#  PATCHED_CONF=$(echo "${AGENT_CONF}" | jq '.agent.sds = {
#    "default_svid_name": "default",
#    "default_bundle_name": "null",
#    "default_all_bundles_name": "ROOTCA"
#  }')
#
#  # Create patch payload
#  oc patch configmap spire-agent --kubeconfig "${kubeconfig}" -n spire-server --type merge -p "{\"data\":{\"agent.conf\":$(echo "${PATCHED_CONF}" | jq -Rs .)}}"
#
#  # Restart spire-agent daemonset to pick up new config
#  oc rollout restart daemonset/spire-agent --kubeconfig "${kubeconfig}" -n spire-server
#  oc rollout status daemonset/spire-agent --kubeconfig "${kubeconfig}" -n spire-server --timeout=300s
#done
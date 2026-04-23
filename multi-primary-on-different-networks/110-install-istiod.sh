source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do


if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_A
else
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_B
fi

# Create Istiod
cat <<EOF | oc apply --kubeconfig="${kubeconfig}" -f -
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: InPlace
  values:
    global:
      meshID: $ISTIO_MESH_ID
      multiCluster:
        clusterName: $ISTIO_MULTI_CLUSTER_NAME
      network: $ISTIO_MULTI_CLUSTER_NETWORK
    meshConfig:
      trustDomain: $ISTIO_MESH_ID
EOF
# Wait till it successfully installed
until oc get deployment istiod --kubeconfig="${kubeconfig}" -n "${OSSM_NS}" &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/istiod --kubeconfig="${kubeconfig}" -n "${OSSM_NS}" --timeout=300s
done
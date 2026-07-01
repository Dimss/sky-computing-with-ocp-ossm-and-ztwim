source "$(dirname "$0")/01-define-exports.sh"

export CLUSTER_A_NODE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane --kubeconfig "${CLUSTER_A_KUBECONFIG}" -o jsonpath='{.items[0].status.addresses[?(@.type == "InternalIP")].address}')
export CLUSTER_B_NODE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane --kubeconfig "${CLUSTER_B_KUBECONFIG}" -o jsonpath='{.items[0].status.addresses[?(@.type == "InternalIP")].address}')

istioctl create-remote-secret \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  --name="${CLUSTER_A}" \
  --server="https://${CLUSTER_A_NODE_IP}:6443" \
  --istioNamespace=istio-system | \
  kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -


istioctl create-remote-secret \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  --name="${CLUSTER_B}" \
  --server="https://${CLUSTER_B_NODE_IP}:6443" \
  --istioNamespace=istio-system | \
  kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -



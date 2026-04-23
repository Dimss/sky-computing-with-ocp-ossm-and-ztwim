source "$(dirname "$0")/01-define-exports.sh"

istioctl create-remote-secret \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  --name="${CLUSTER_A}" | \
  kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -

istioctl create-remote-secret \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  --name="${CLUSTER_B}" | \
  kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -

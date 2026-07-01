source "$(dirname "$0")/01-define-exports.sh"

istioctl waypoint apply --enroll-namespace --for service --namespace sample --kubeconfig="$CLUSTER_B_KUBECONFIG" --overwrite

istioctl waypoint apply --enroll-namespace --for service --namespace sample --kubeconfig="$CLUSTER_A_KUBECONFIG" --overwrite

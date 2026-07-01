source "$(dirname "$0")/01-define-exports.sh"

kubectl patch deployment helloworld-v1  \
 -n sample \
 --patch '{"spec": {"template": {"metadata": {"labels": {"istio.io/use-waypoint": "waypoint"}}}}}' \
 --kubeconfig="$CLUSTER_B_KUBECONFIG"

istioctl waypoint apply --enroll-namespace --wait --namespace sample --kubeconfig="$CLUSTER_B_KUBECONFIG"


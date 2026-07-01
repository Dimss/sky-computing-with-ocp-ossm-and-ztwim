source "$(dirname "$0")/01-define-exports.sh"

#kubectl label service helloworld istio.io/ingress-use-waypoint=true -n sample --kubeconfig="$CLUSTER_A_KUBECONFIG"

kubectl label service helloworld istio.io/ingress-use-waypoint=true -n sample --kubeconfig="$CLUSTER_B_KUBECONFIG"
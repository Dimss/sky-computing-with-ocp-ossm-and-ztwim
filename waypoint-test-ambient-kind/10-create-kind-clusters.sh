source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | kind create cluster --kubeconfig="${CLUSTER_B_KUBECONFIG}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_B
nodes:
- role: control-plane
EOF
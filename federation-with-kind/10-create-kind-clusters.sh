source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | kind create cluster --kubeconfig="${CLUSTER_A_KUBECONFIG}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_A
nodes:
- role: control-plane
  extraPortMappings:
  - hostPort: 8080
    protocol: TCP
    containerPort: 30980
  - hostPort: $CLUSTER_A_HOST_HTTPS_PORT
    protocol: TCP
    containerPort: 30943
EOF

cat <<EOF | kind create cluster --kubeconfig="${CLUSTER_B_KUBECONFIG}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $CLUSTER_B
nodes:
- role: control-plane
  extraPortMappings:
  - hostPort: 8081
    protocol: TCP
    containerPort: 30980
  - hostPort: $CLUSTER_B_HOST_HTTPS_PORT
    protocol: TCP
    containerPort: 30943
EOF
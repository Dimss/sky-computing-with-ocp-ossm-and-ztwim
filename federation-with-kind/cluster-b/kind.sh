cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster-b
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30980
    hostPort: 8081
    protocol: TCP
  - containerPort: 30943
    hostPort: 9443
    protocol: TCP
EOF
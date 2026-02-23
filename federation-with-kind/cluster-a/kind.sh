cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster-a
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30980
    hostPort: 8080
    protocol: TCP
  - containerPort: 30943
    hostPort: 8443
    protocol: TCP
EOF
export ISTIO_MESH_ID=istio-federation
export CLUSTER_A=cluster-a
export CLUSTER_B=cluster-b
export NETWORK_A=network-a
export NETWORK_B=network-b
export CLUSTER_A_KUBECONFIG=$(dirname "$0")/cluster-a.kubeconfig
export CLUSTER_B_KUBECONFIG=$(dirname "$0")/cluster-b.kubeconfig


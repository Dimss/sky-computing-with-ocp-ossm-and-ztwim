export NIPIP_LB_IP=192.168.64.8
export NIPIP_LB_NAMESPACE=nipip-lb
export CLUSTER_A=cluster-a
export CLUSTER_B=cluster-b
export NETWORK_A=network-a
export NETWORK_B=network-b
export CLUSTER_A_HOST_HTTPS_PORT=8443
export CLUSTER_B_HOST_HTTPS_PORT=9443
export CLUSTER_A_KUBECONFIG=$(dirname "$0")/cluster-a.kubeconfig
export CLUSTER_B_KUBECONFIG=$(dirname "$0")/cluster-b.kubeconfig


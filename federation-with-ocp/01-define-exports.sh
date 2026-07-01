export ZTWIM_NS=zero-trust-workload-identity-manager
export OSSM_NS=istio-system
export OSSM_CNI=istio-cni
export CLUSTER_A_KUBECONFIG=$(pwd)/cluster-a.kubeconfig
export CLUSTER_B_KUBECONFIG=$(pwd)/cluster-b.kubeconfig
export CLUSTER_A_BASE_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain} --kubeconfig "${CLUSTER_A_KUBECONFIG}")
export CLUSTER_B_BASE_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain} --kubeconfig "${CLUSTER_B_KUBECONFIG}")
export CLUSTER_A=cluster-a
export CLUSTER_B=cluster-b
export NETWORK_A=network-a
export NETWORK_B=network-b
export JWT_ISSUER_CLUSTER_A="https://oidc-discovery.$CLUSTER_A_BASE_DOMAIN"
export JWT_ISSUER_CLUSTER_B="https://oidc-discovery.$CLUSTER_B_BASE_DOMAIN"
export FEDERATION_ENDPOINT_CLUSTER_A="https://federation.$CLUSTER_A_BASE_DOMAIN"
export FEDERATION_ENDPOINT_CLUSTER_B="https://federation.$CLUSTER_B_BASE_DOMAIN"
export VALIDATOR_DOMAIN_CLUSTER_A="validator.$CLUSTER_A_BASE_DOMAIN"
export SPIFFE_AUDIENCE="federation-test"
export ZTWIM_NS=zero-trust-workload-identity-manager
export CLUSTER_A_KUBECONFIG=$(dirname "$0")/cluster-a.kubeconfig
export CLUSTER_B_KUBECONFIG=$(dirname "$0")/cluster-b.kubeconfig
export CLUSTER_A=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain} --kubeconfig "${CLUSTER_A_KUBECONFIG}")
export CLUSTER_B=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain} --kubeconfig "${CLUSTER_B_KUBECONFIG}")
export JWT_ISSUER_CLUSTER_A="https://oidc-discovery.$CLUSTER_A"
export JWT_ISSUER_CLUSTER_B="https://oidc-discovery.$CLUSTER_B"
export FEDERATION_ENDPOINT_CLUSTER_A="https://federation.$CLUSTER_A"
export FEDERATION_ENDPOINT_CLUSTER_B="https://federation.$CLUSTER_B"
export VALIDATOR_DOMAIN_CLUSTER_A="validator.$CLUSTER_A"

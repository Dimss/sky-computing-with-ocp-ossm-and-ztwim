export ZTWIM_NS=zero-trust-workload-identity-manager
export TRUST_DOMAIN=sky.computing.ocp.one
export JWT_ISSUER="https://oidc-discovery.$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
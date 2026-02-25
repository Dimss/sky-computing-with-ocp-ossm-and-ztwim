source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply --kubeconfig "${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireOIDCDiscoveryProvider
metadata:
  name: cluster
spec:
  logLevel: "info"
  logFormat: "text"
  csiDriverName: "csi.spiffe.io"
  jwtIssuer: $JWT_ISSUER_CLUSTER_A
  replicaCount: 1
  managedRoute: "true"
EOF

until oc get deployment spire-spiffe-oidc-discovery-provider --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done

oc wait --for=condition=Available deployment/spire-spiffe-oidc-discovery-provider --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n "${ZTWIM_NS}" --timeout=300s


cat <<EOF | oc apply --kubeconfig "${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireOIDCDiscoveryProvider
metadata:
  name: cluster
spec:
  logLevel: "info"
  logFormat: "text"
  csiDriverName: "csi.spiffe.io"
  jwtIssuer: $JWT_ISSUER_CLUSTER_B
  replicaCount: 1
  managedRoute: "true"
EOF

until oc get deployment spire-spiffe-oidc-discovery-provider --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done

oc wait --for=condition=Available deployment/spire-spiffe-oidc-discovery-provider --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n "${ZTWIM_NS}" --timeout=300s

source "$(dirname "$0")/01-define-exports.sh"

oc apply -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ZeroTrustWorkloadIdentityManager
metadata:
 name: cluster
 labels:
   app.kubernetes.io/name: zero-trust-workload-identity-manager
   app.kubernetes.io/managed-by: zero-trust-workload-identity-manager
spec:
  trustDomain: ${TRUST_DOMAIN}
  clusterName: "sky-computing-cluster"
  bundleConfigMap: "spire-bundle"
EOF


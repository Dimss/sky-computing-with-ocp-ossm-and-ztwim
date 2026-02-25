source "$(dirname "$0")/01-define-exports.sh"

oc apply --kubeconfig "${CLUSTER_A_KUBECONFIG}" -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ZeroTrustWorkloadIdentityManager
metadata:
 name: cluster
 labels:
   app.kubernetes.io/name: zero-trust-workload-identity-manager
   app.kubernetes.io/managed-by: zero-trust-workload-identity-manager
spec:
  trustDomain: ${CLUSTER_A}
  clusterName: ${CLUSTER_A}
  bundleConfigMap: "spire-bundle"
EOF

oc apply --kubeconfig "${CLUSTER_B_KUBECONFIG}" -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ZeroTrustWorkloadIdentityManager
metadata:
 name: cluster
 labels:
   app.kubernetes.io/name: zero-trust-workload-identity-manager
   app.kubernetes.io/managed-by: zero-trust-workload-identity-manager
spec:
  trustDomain: ${CLUSTER_B}
  clusterName: ${CLUSTER_B}
  bundleConfigMap: "spire-bundle"
EOF



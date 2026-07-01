source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
# Install OSSM3.x operator
oc apply --kubeconfig="${kubeconfig}" -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator3
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator3
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

until oc get deployment servicemesh-operator3 --kubeconfig="${kubeconfig}" -n openshift-operators &> /dev/null; do sleep 3; done

oc wait --for=condition=Available deployment/servicemesh-operator3 --kubeconfig="${kubeconfig}" -n openshift-operators --timeout=300s

done

source "$(dirname "$0")/01-define-exports.sh"

# Install OSSM3.x operator
oc apply -f - <<EOF
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
# Wait till the OSSM operator has been installed successfully
until oc get deployment servicemesh-operator3 -n openshift-operators &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/servicemesh-operator3 -n openshift-operators --timeout=300s

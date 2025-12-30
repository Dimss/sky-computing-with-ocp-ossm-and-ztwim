source "$(dirname "$0")/01-define-exports.sh"

oc new-project "$ZTWIM_NS" 2>/dev/null || oc project "$ZTWIM_NS"

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-zero-trust-workload-identity-manager
  namespace: $ZTWIM_NS
spec:
  upgradeStrategy: Default
EOF
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-zero-trust-workload-identity-manager
  namespace: $ZTWIM_NS
spec:
  channel: stable-v1
  name: openshift-zero-trust-workload-identity-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF

oc -n "$ZTWIM_NS" patch subscription \
  openshift-zero-trust-workload-identity-manager \
  --type='merge' -p '{"spec":{"config":{"env":[{"name":"CREATE_ONLY_MODE","value":"true"}]}}}'

until oc get deployment zero-trust-workload-identity-manager-controller-manager  -n "${ZTWIM_NS}" &> /dev/null; do
  sleep 3
done

oc wait --for=condition=Available deployment/zero-trust-workload-identity-manager-controller-manager -n "${ZTWIM_NS}" --timeout=300s
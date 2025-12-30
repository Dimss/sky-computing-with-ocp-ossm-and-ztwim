source "$(dirname "$0")/01-define-exports.sh"

oc new-project "${OSSM_CNI}" 2>/dev/null  || oc project "${OSSM_CNI}"
# Create IstioCNI and wait till it successfully installed
oc apply -f - <<EOF
apiVersion: sailoperator.io/v1
kind: IstioCNI
metadata:
  name: default
spec:
  namespace: ${OSSM_CNI}
EOF
until oc get daemonset/istio-cni-node -n "${OSSM_CNI}" &> /dev/null; do sleep 3; done
kubectl rollout status daemonset/istio-cni-node -n "${OSSM_CNI}" --timeout=300s
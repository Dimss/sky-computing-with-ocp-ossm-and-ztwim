source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

oc new-project "${OSSM_CNI}" --kubeconfig="${kubeconfig}"
# Create IstioCNI and wait till it successfully installed
oc apply --kubeconfig="${kubeconfig}" -f - <<EOF
apiVersion: sailoperator.io/v1
kind: IstioCNI
metadata:
  name: default
spec:
  namespace: ${OSSM_CNI}
EOF

until oc get daemonset/istio-cni-node --kubeconfig="${kubeconfig}" -n "${OSSM_CNI}" &> /dev/null; do sleep 3; done

kubectl rollout status daemonset/istio-cni-node --kubeconfig="${kubeconfig}" -n "${OSSM_CNI}" --timeout=300s

done
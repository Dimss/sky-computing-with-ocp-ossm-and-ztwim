source "$(dirname "$0")/01-define-exports.sh"

oc adm policy add-scc-to-user anyuid -z istio-eastwestgateway -n istio-system --kubeconfig="${CLUSTER_A_KUBECONFIG}"
oc adm policy add-scc-to-user anyuid -z istio-eastwestgateway -n istio-system --kubeconfig="${CLUSTER_B_KUBECONFIG}"

helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_A}" \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}"



helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_B}" \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}"

source "$(dirname "$0")/01-define-exports.sh"

helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_A}" \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}"

helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_B}" \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

oc adm policy add-scc-to-user anyuid -z istio-eastwestgateway -n istio-system --kubeconfig="${kubeconfig}"

done




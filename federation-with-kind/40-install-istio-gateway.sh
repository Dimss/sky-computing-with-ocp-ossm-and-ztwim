source "$(dirname "$0")/01-define-exports.sh"

# regular ingress gateway
for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
  helm upgrade --install istio-gateway -n istio-system \
    istio/gateway \
    --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
    --kubeconfig="${kubeconfig}"
done

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









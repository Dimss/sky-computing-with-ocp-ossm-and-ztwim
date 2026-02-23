source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
  helm upgrade --install istio-gateway -n istio-system \
    istio/gateway \
    --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
    --set-json 'service.ports=[{"name": "status-port","port": 15021,"protocol": "TCP","targetPort": 15021},{"name": "http2","nodePort": 30980,"port": 80,"protocol": "TCP","targetPort": 80},{"name": "https","nodePort": 30943,"port": 443,"protocol": "TCP","targetPort": 443}]' \
    --kubeconfig="${kubeconfig}"
done






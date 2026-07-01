source "$(dirname "$0")/01-define-exports.sh"

oc apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f - <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: $NETWORK_A
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF


oc apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f - <<EOF
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: $NETWORK_B
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF

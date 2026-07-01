source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | istioctl install -y --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        overlays:
          - apiVersion: apps/v1
            kind: Deployment
            name: istiod
            patches:
              - path: spec.template.spec.containers.[name:discovery].image
                value: docker.io/dimssss/istiod-fix-arm64:v1
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
          - name: AMBIENT_ENABLE_BAGGAGE
            value: "true"
          - name: AMBIENT_ENABLE_MULTI_NETWORK_INGRESS
            value: "true"
          - name: ENABLE_INGRESS_WAYPOINT_ROUTING
            value: "true"
          - name: PILOT_ENABLE_METADATA_EXCHANGE
            value: "false"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: $CLUSTER_A
      network: $NETWORK_A
EOF

cat <<EOF | kubectl apply --kubeconfig "${CLUSTER_A_KUBECONFIG}" -f -
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "${NETWORK_A}"
  annotations:
    sidecar.istio.io/proxyImage: dimssss/proxyv2:v1
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF


cat <<EOF | istioctl install -y --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        overlays:
          - apiVersion: apps/v1
            kind: Deployment
            name: istiod
            patches:
              - path: spec.template.spec.containers.[name:discovery].image
                value: docker.io/dimssss/istiod-fix-arm64:v1
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
          - name: AMBIENT_ENABLE_BAGGAGE
            value: "true"
          - name: AMBIENT_ENABLE_MULTI_NETWORK_INGRESS
            value: "true"
          - name: ENABLE_INGRESS_WAYPOINT_ROUTING
            value: "true"
          - name: PILOT_ENABLE_METADATA_EXCHANGE
            value: "false"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: $CLUSTER_B
      network: $NETWORK_B
EOF

cat <<EOF | kubectl apply --kubeconfig "${CLUSTER_B_KUBECONFIG}" -f -
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "${NETWORK_B}"
  annotations:
    sidecar.istio.io/proxyImage: dimssss/proxyv2:v1
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF

#          - name: AMBIENT_ENABLE_MULTI_NETWORK_INGRESS
#            value: "true"
#          - name: ENABLE_INGRESS_WAYPOINT_ROUTING
#            value: "false"
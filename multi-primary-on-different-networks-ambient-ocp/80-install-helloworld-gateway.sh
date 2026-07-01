source "$(dirname "$0")/01-define-exports.sh"

export SAMPLE_NS=sample

cat <<EOF | kubectl apply --kubeconfig "${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: helloworld-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: helloworld-route
  namespace: ${SAMPLE_NS}
spec:
  parentRefs:
  - name: helloworld-gateway
    namespace: istio-system
  hostnames:
  - "helloworld"
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF


cat <<EOF | kubectl apply --kubeconfig "${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: helloworld-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: helloworld-route
  namespace: ${SAMPLE_NS}
spec:
  parentRefs:
  - name: helloworld-gateway
    namespace: istio-system
  hostnames:
  - "helloworld"
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF

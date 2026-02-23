source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

export BASE_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${kubeconfig}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
    - name: http
      port: 80
      targetPort: 8080
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/mccutchen/go-httpbin:v2.15.0
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 8080
EOF

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: default
spec:
  selector:
    istio: gateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "httpbin.$BASE_DOMAIN"
EOF

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
  namespace: default
spec:
  hosts:
    - "httpbin.$BASE_DOMAIN"
  gateways:
    - httpbin-gateway
  http:
    - route:
      - destination:
          host: httpbin.default.svc.cluster.local
          port:
            number: 80
EOF

done
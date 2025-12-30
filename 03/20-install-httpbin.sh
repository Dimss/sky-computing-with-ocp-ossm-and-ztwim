source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: ${TPJ}
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: ${TPJ}
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - name: http-ex-spiffe
    port: 443
    targetPort: 8080
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
  namespace: ${TPJ}
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
        spiffe.io/audience: "${SPIFFE_AUDIENCE}"
      labels:
        app: httpbin
        version: v1
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/mccutchen/go-httpbin:v2.15.0
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 8080
EOF
until oc get deployment httpbin -n "${TPJ}" &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/httpbin -n "${TPJ}" --timeout=300s

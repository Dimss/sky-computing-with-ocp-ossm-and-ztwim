source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: curl
  namespace: ${TPJ}
---
apiVersion: v1
kind: Service
metadata:
  name: curl
  namespace: ${TPJ}
  labels:
    app: curl
    service: curl
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: curl
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
  namespace: ${TPJ}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: curl
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
        spiffe.io/audience: "${SPIFFE_AUDIENCE}"
      labels:
        app: curl
    spec:
      terminationGracePeriodSeconds: 0
      serviceAccountName: curl
      containers:
      - name: curl
        image: curlimages/curl:8.16.0
        command:
        - /bin/sh
        - -c
        - sleep inf
        imagePullPolicy: IfNotPresent
      - name: aws-cli
        image: public.ecr.aws/aws-cli/aws-cli
        command:
        - /bin/sh
        - -c
        - sleep inf
        imagePullPolicy: IfNotPresent
EOF
until oc get deployment curl -n "${TPJ}" &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/curl -n "${TPJ}" --timeout=300s

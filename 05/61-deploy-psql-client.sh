source "$(dirname "$0")/01-define-exports.sh"


cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: psql
  namespace: ${TPJ}
spec:
  selector:
    matchLabels:
      app: psql
      version: v1
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
        spiffe.io/audience: "sky-computing-demo"
      labels:
        app: psql
        version: v1
    spec:
      containers:
      - image: postgres:16.9
        imagePullPolicy: IfNotPresent
        name: psql
        command:
          - /bin/bash
          - -c
          - sleep inf
EOF

until oc get deployment psql -n "${TPJ}" &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/psql -n "${TPJ}" --timeout=300s
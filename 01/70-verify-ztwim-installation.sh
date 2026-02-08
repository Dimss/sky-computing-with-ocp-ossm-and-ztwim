source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ztwim-client
  namespace: default
  labels:
    app: ztwim-client
spec:
  selector:
    matchLabels:
      app: ztwim-client
  template:
    metadata:
      labels:
        app: ztwim-client
    spec:
      containers:
        - name: client
          image: ghcr.io/spiffe/spire-agent:1.5.1
          command: ["/opt/spire/bin/spire-agent"]
          args: [ "api", "watch",  "-socketPath", "/run/spire/sockets/spire-agent.sock" ]
          volumeMounts:
            - mountPath: /run/spire/sockets
              name: spiffe-workload-api
              readOnly: true
      volumes:
      - name: spiffe-workload-api
        csi:
          driver: csi.spiffe.io
          readOnly: true
EOF
until oc get deployment ztwim-client -n default &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/ztwim-client -n default --timeout=300s
sleep 5 # this 5 second sleep insures that required spire entry has been created by the spire controller
oc exec -it \
  "$(oc get \
      pods -o=jsonpath='{.items[0].metadata.name}' \
      -l app=ztwim-client \
      -n default \
   )" -n default -- \
  /opt/spire/bin/spire-agent \
    api fetch -socketPath /run/spire/sockets/spire-agent.sock


source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: spire-server
  namespace: ${ZTWIM_NS}
spec:
  host: ${SPIRE_SERVER_DOMAIN}
  port:
    targetPort: grpc
  tls:
    termination: passthrough
  to:
    kind: Service
    name: spire-server
    weight: 100
EOF
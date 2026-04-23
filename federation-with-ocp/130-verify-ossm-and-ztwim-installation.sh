source "$(dirname "$0")/01-define-exports.sh"

export VERIFY_NS=verify-ossm-ztwim

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

oc new-project "${VERIFY_NS}" --kubeconfig="${kubeconfig}"
# enable sidecar injection
oc label namespace "${VERIFY_NS}" istio-injection=enabled --kubeconfig="${kubeconfig}"
# create httpbin workload
cat <<EOF | oc apply --kubeconfig="${kubeconfig}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: ${VERIFY_NS}
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
        spiffe.io/audience: "sky-computing-demo"
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
until oc get deployment httpbin --kubeconfig="${kubeconfig}" -n "${VERIFY_NS}" &> /dev/null; do sleep 3; done
oc wait --kubeconfig="${kubeconfig}" --for=condition=Available deployment/httpbin -n "${VERIFY_NS}" --timeout=300s
# Verify ZTWIM identity
HTTPBIN_POD=$(oc get pod --kubeconfig="${kubeconfig}" -l app=httpbin -n "${VERIFY_NS}" -o jsonpath="{.items[0].metadata.name}")
istioctl proxy-config --kubeconfig="${kubeconfig}" secret "$HTTPBIN_POD" \
 -n "${VERIFY_NS}" -o json \
 | jq -r  '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' \
 | base64  --decode > chain.pem
openssl x509 -in chain.pem -text | grep SPIRE
done

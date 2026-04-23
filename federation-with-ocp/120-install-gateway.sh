source "$(dirname "$0")/01-define-exports.sh"

helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_A}" \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}"

helm upgrade --install istio-eastwestgateway istio/gateway \
  -n istio-system \
  --set-json 'podAnnotations={"inject.istio.io/templates":"gateway,spireGw"}' \
  --set name=istio-eastwestgateway \
  --set networkGateway="${NETWORK_B}" \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

oc adm policy add-scc-to-user anyuid -z istio-eastwestgateway -n istio-system --kubeconfig="${kubeconfig}"

if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
    export FEDERATED_WITH=$CLUSTER_B
  else
    export FEDERATED_WITH=$CLUSTER_A
fi

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-eastwestgateway
spec:
  autoPopulateDNSNames: true
  className: zero-trust-workload-identity-manager-spire
  fallback: true
  federatesWith:
    - $FEDERATED_WITH
  hint: default
  podSelector:
    matchLabels:
      app: "istio-eastwestgateway"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF

POD=$(oc get pod --kubeconfig="${kubeconfig}" -l app=istio-eastwestgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
istioctl proxy-config --kubeconfig="${kubeconfig}" secret "$POD" \
 -n istio-system -o json \
 | jq -r  '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' \
 | base64  --decode > chain.pem
openssl x509 -in chain.pem -text | grep SPIRE

done




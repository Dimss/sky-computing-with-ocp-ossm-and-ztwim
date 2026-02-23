source "$(dirname "$0")/01-define-exports.sh"

export CLUSTER_A_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

export CLUSTER_B_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${CLUSTER_B_KUBECONFIG}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

kubectl exec -it spire-server-0 -n spire-server \
 --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -- spire-server bundle show -format spiffe > fed_bundle_cluster_a

 kubectl exec -it spire-server-0 -n spire-server \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -- spire-server bundle show -format spiffe > fed_bundle_cluster_b

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
  # Get current config and validate JSON
  CURRENT_CONFIG=$(kubectl get configmap spire-server -n spire-server --kubeconfig="${kubeconfig}" -o jsonpath='{.data.server\.conf}')

  # Validate current JSON
  echo "Validating current JSON..."
  if ! echo "$CURRENT_CONFIG" | jq . > /dev/null 2>&1; then
      echo "ERROR: Current server.conf is not valid JSON. Please fix the ConfigMap first."
      exit 1
  fi
  export BASE_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${kubeconfig}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)
  # Configure federation settings based on cluster
  if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
    echo "Configuring federation for cluster-a..."
    export REMOTE_CLUSTER="cluster-b"
    export REMOTE_SPIFFE_ID="spiffe://cluster-b/spire/server"
    export REMOTE_BUNDLE_ENDPOINT_URL="https://spire-bundle.${CLUSTER_B_DOMAIN}:${CLUSTER_B_HOST_HTTPS_PORT}"
    export REMOTE_TRUST_DOMAIN_BUNDLE="$(sed 's/^/    /' ./fed_bundle_cluster_b)"
  else
    echo "Configuring federation for cluster-b..."
    export REMOTE_CLUSTER="cluster-a"
    export REMOTE_SPIFFE_ID="spiffe://cluster-a/spire/server"
    export REMOTE_BUNDLE_ENDPOINT_URL="https://spire-bundle.${CLUSTER_A_DOMAIN}:${CLUSTER_A_HOST_HTTPS_PORT}"
    export REMOTE_TRUST_DOMAIN_BUNDLE="$(sed 's/^/    /' ./fed_bundle_cluster_a)"
  fi

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterFederatedTrustDomain
metadata:
  name: $REMOTE_CLUSTER
spec:
  className: spire-server-spire
  trustDomain: $REMOTE_CLUSTER
  bundleEndpointURL: $REMOTE_BUNDLE_ENDPOINT_URL
  bundleEndpointProfile:
    type: https_spiffe
    endpointSPIFFEID: $REMOTE_SPIFFE_ID
  trustDomainBundle: |-
$REMOTE_TRUST_DOMAIN_BUNDLE

EOF


export BASE_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${kubeconfig}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: spire-gateway
  namespace: spire-server
spec:
  selector:
    istio: gateway
  servers:
    - port:
        number: 443
        name: tls-passthrough
        protocol: TLS
      tls:
        mode: PASSTHROUGH
      hosts:
        - "spire-bundle.$BASE_DOMAIN"
EOF

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: spire-gateway
  namespace: spire-server
spec:
  hosts:
    - "spire-bundle.$BASE_DOMAIN"
  gateways:
    - spire-gateway
  tls:
    - match:
      - port: 443
        sniHosts:
        - "spire-bundle.$BASE_DOMAIN"
      route:
      - destination:
          host: spire-server.spire-server.svc.cluster.local
          port:
            number: 8443
EOF

done
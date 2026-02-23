source "$(dirname "$0")/01-define-exports.sh"

export CLUSTER_A_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)
export CLUSTER_B_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${CLUSTER_B_KUBECONFIG}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

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
  else
    echo "Configuring federation for cluster-b..."
    export REMOTE_CLUSTER="cluster-a"
    export REMOTE_SPIFFE_ID="spiffe://cluster-a/spire/server"
    export REMOTE_BUNDLE_ENDPOINT_URL="https://spire-bundle.${CLUSTER_A_DOMAIN}:${CLUSTER_A_HOST_HTTPS_PORT}"
  fi

# Federation configuration using dynamic values
FEDERATION_CONFIG=$(cat << EOF
{
  "bundle_endpoint": {
    "address": "0.0.0.0",
    "port": 8443
  },
  "federates_with": {
    "${REMOTE_CLUSTER}": {
      "bundle_endpoint_url": "${REMOTE_BUNDLE_ENDPOINT_URL}",
      "bundle_endpoint_profile": {
        "https_spiffe": {
          "endpoint_spiffe_id": "${REMOTE_SPIFFE_ID}"
        }
      }
    }
  }
}
EOF
)

# Merge federation config into server block
echo "Merging federation configuration..."
MERGED_CONFIG=$(echo "$CURRENT_CONFIG" | jq --argjson fed "$FEDERATION_CONFIG" '.server.federation = $fed')

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to merge federation configuration"
    exit 1
fi

# Show the merged config for review
echo "Merged configuration:"
echo "$MERGED_CONFIG" | jq .

# Apply the patch
echo "Applying configuration..."
kubectl patch configmap spire-server -n spire-server --kubeconfig="${kubeconfig}" --type='merge' -p="{\"data\":{\"server.conf\":\"$(echo "$MERGED_CONFIG" | jq -c . | sed 's/"/\\"/g')\"}}"

if [ $? -eq 0 ]; then
    echo "Successfully patched spire-server ConfigMap!"

    # Restart the StatefulSet to pick up the new configuration
    echo "Restarting spire-server StatefulSet to apply federation configuration..."
    kubectl rollout restart statefulset spire-server -n spire-server --kubeconfig="${kubeconfig}"

    # Wait for rollout to complete
    echo "Waiting for StatefulSet rollout to complete..."
    kubectl rollout status statefulset spire-server -n spire-server --kubeconfig="${kubeconfig}" --timeout=300s

    if [ $? -eq 0 ]; then
        echo "Successfully restarted spire-server StatefulSet!"
    else
        echo "WARNING: StatefulSet restart may not have completed successfully"
    fi
else
    echo "ERROR: Failed to patch ConfigMap"
    exit 1
fi

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
source "$(dirname "$0")/01-define-exports.sh"

export CLUSTER_A_DOMAIN="$(kubectl get svc spire-server --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n spire-server -ojsonpath={.status.loadBalancer.ingress[].ip}):8443"
export CLUSTER_B_DOMAIN="$(kubectl get svc spire-server --kubeconfig="${CLUSTER_B_KUBECONFIG}" -n spire-server -ojsonpath={.status.loadBalancer.ingress[].ip}):8443"

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
  # Configure federation settings based on cluster
  if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
    echo "Configuring federation for cluster-a..."
    export REMOTE_CLUSTER="cluster-b"
    export REMOTE_SPIFFE_ID="spiffe://cluster-b/spire/server"
    export REMOTE_BUNDLE_ENDPOINT_URL="https://${CLUSTER_B_DOMAIN}"
    export REMOTE_TRUST_DOMAIN_BUNDLE="$(sed 's/^/    /' ./fed_bundle_cluster_b)"
  else
    echo "Configuring federation for cluster-b..."
    export REMOTE_CLUSTER="cluster-a"
    export REMOTE_SPIFFE_ID="spiffe://cluster-a/spire/server"
    export REMOTE_BUNDLE_ENDPOINT_URL="https://${CLUSTER_A_DOMAIN}"
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

done

kubectl exec \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  -c spire-server \
  -n spire-server \
  spire-server-0 \
  -- spire-server federation list -output json \
  | jq -r .federation_relationships[].trust_domain

# should return cluster-a
kubectl exec \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -c spire-server \
  -n spire-server \
  spire-server-0 \
  -- spire-server federation list -output json \
  | jq -r .federation_relationships[].trust_domain


#
## Patch ClusterSPIFFEID on CLUSTER A to federate with CLUSTER B
#kubectl patch clusterspiffeid spire-server-spire-default \
#  --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
#  --type=merge \
#  -p "{\"spec\":{\"federatesWith\":[\"${CLUSTER_B}\"],\"autoPopulateDNSNames\":true}}"
#
## Patch ClusterSPIFFEID on CLUSTER B to federate with CLUSTER A
#kubectl patch clusterspiffeid spire-server-spire-default \
#  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
#  --type=merge \
#  -p "{\"spec\":{\"federatesWith\":[\"${CLUSTER_A}\"],\"autoPopulateDNSNames\":true}}"
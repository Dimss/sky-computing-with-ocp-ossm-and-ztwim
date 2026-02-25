source "$(dirname "$0")/01-define-exports.sh"

kubectl exec -it spire-server-0 -n "$ZTWIM_NS" \
 --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -- /spire-server bundle show -format spiffe > fed_bundle_cluster_a

kubectl exec -it spire-server-0 -n "$ZTWIM_NS" \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -- /spire-server bundle show -format spiffe > fed_bundle_cluster_b

# Federation setup for CLUSTER A
export REMOTE_CLUSTER=${CLUSTER_B}
export REMOTE_SPIFFE_ID="spiffe://${CLUSTER_B}/spire/server"
export REMOTE_BUNDLE_ENDPOINT_URL=$FEDERATION_ENDPOINT_CLUSTER_B
export REMOTE_TRUST_DOMAIN_BUNDLE="$(sed 's/^/    /' ./fed_bundle_cluster_b)"

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterFederatedTrustDomain
metadata:
  name: $REMOTE_CLUSTER
spec:
  className: zero-trust-workload-identity-manager-spire
  trustDomain: $REMOTE_CLUSTER
  bundleEndpointURL: $REMOTE_BUNDLE_ENDPOINT_URL
  bundleEndpointProfile:
    type: https_spiffe
    endpointSPIFFEID: $REMOTE_SPIFFE_ID
  trustDomainBundle: |-
$REMOTE_TRUST_DOMAIN_BUNDLE
EOF


# Federation setup for CLUSTER B
export REMOTE_CLUSTER=${CLUSTER_A}
export REMOTE_SPIFFE_ID="spiffe://${CLUSTER_A}/spire/server"
export REMOTE_BUNDLE_ENDPOINT_URL=$FEDERATION_ENDPOINT_CLUSTER_A
export REMOTE_TRUST_DOMAIN_BUNDLE="$(sed 's/^/    /' ./fed_bundle_cluster_a)"

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterFederatedTrustDomain
metadata:
  name: $REMOTE_CLUSTER
spec:
  className: zero-trust-workload-identity-manager-spire
  trustDomain: $REMOTE_CLUSTER
  bundleEndpointURL: $REMOTE_BUNDLE_ENDPOINT_URL
  bundleEndpointProfile:
    type: https_spiffe
    endpointSPIFFEID: $REMOTE_SPIFFE_ID
  trustDomainBundle: |-
$REMOTE_TRUST_DOMAIN_BUNDLE
EOF

#
#export TRUST_DOMAIN_BUNDLE=$(curl -s -k  https://federation.$FEDERATED_TRUST_DOMAIN | sed 's/^/   /')
#
#cat <<EOF | $oc apply -f -
#apiVersion: spire.spiffe.io/v1alpha1
#kind: ClusterFederatedTrustDomain
#metadata:
#  name: cluster-b-federation
#spec:
#  trustDomain: $FEDERATED_TRUST_DOMAIN
#  bundleEndpointURL: https://federation.$FEDERATED_TRUST_DOMAIN
#  bundleEndpointProfile:
#    type: https_spiffe
#    endpointSPIFFEID: spiffe://$FEDERATED_TRUST_DOMAIN/spire/server
#  trustDomainBundle: |
#$TRUST_DOMAIN_BUNDLE
#EOF
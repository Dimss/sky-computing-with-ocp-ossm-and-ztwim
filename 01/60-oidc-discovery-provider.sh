source "$(dirname "$0")/01-define-exports.sh"
export OIDC_DISCOVERY_CONFIG_MAP=spire-spiffe-oidc-discovery-provider
cat <<EOF | oc apply -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireOIDCDiscoveryProvider
metadata:
  name: cluster
spec:
  logLevel: "info"
  logFormat: "text"
  csiDriverName: "csi.spiffe.io"
  jwtIssuer: $JWT_ISSUER
  replicaCount: 1
  managedRoute: "true"
EOF
# wait for the deployment being created
until oc get deployment spire-spiffe-oidc-discovery-provider -n "${ZTWIM_NS}" &> /dev/null; do sleep 3; done
# patch configuration
#export PATCH_PAYLOAD=$(kubectl get configmap ${OIDC_DISCOVERY_CONFIG_MAP} -n "${ZTWIM_NS}" -o json | \
#  jq -r '.data["oidc-discovery-provider.conf"] | fromjson | .workload_api.socket_path = "/spiffe-workload-api/socket" | tojson | {data: {"oidc-discovery-provider.conf": .}}')
#kubectl patch configmap ${OIDC_DISCOVERY_CONFIG_MAP} -n "${ZTWIM_NS}" --patch "$PATCH_PAYLOAD"
# rollout restart
#kubectl rollout restart deployment/spire-spiffe-oidc-discovery-provider -n "${ZTWIM_NS}"
# wait for deployment to be ready
oc wait --for=condition=Available deployment/spire-spiffe-oidc-discovery-provider -n "${ZTWIM_NS}" --timeout=300s

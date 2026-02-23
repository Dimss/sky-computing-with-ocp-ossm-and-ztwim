source "$(dirname "$0")/01-define-exports.sh"

helm upgrade --install \
   -n spire-server spire-crds \
   spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ \
   --create-namespace \
   --kubeconfig="${CLUSTER_A_KUBECONFIG}"

helm upgrade --install \
   -n spire-server spire \
    spire --repo https://spiffe.github.io/helm-charts-hardened/ \
    --set global.spire.trustDomain="${CLUSTER_A}" \
    --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
    --set spire-server.federation.enabled=true

helm upgrade --install \
   -n spire-server spire-crds \
   spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ \
   --create-namespace \
   --kubeconfig="${CLUSTER_B_KUBECONFIG}"

helm upgrade --install \
   -n spire-server spire \
    spire --repo https://spiffe.github.io/helm-charts-hardened/ \
    --set global.spire.trustDomain="${CLUSTER_B}" \
    --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
    --set spire-server.federation.enabled=true
source "$(dirname "$0")/01-define-exports.sh"

kubectl exec -it spire-server-0 -n spire-server \
 --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -- spire-server bundle show -format spiffe > fed_bundle_cluster_a

 kubectl exec -it spire-server-0 -n spire-server \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -- spire-server bundle show -format spiffe > fed_bundle_cluster_b

kubectl create configmap spire-server -n spire-server \
  --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  --from-file=fed-bundle=fed_bundle_cluster_b \
  -o yaml --dry-run=client | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -

kubectl create configmap spire-server -n spire-server \
  --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  --from-file=fed-bundle=fed_bundle_cluster_a \
  -o yaml --dry-run=client | kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -

echo "Restarting spire-server StatefulSet to apply federation configuration..."
kubectl rollout restart statefulset spire-server -n spire-server --kubeconfig="${CLUSTER_A_KUBECONFIG}"

echo "Restarting spire-server StatefulSet to apply federation configuration..."
kubectl rollout restart statefulset spire-server -n spire-server --kubeconfig="${CLUSTER_B_KUBECONFIG}"

# Wait for rollout to complete
echo "Waiting for StatefulSet rollout to complete..."
kubectl rollout status statefulset spire-server -n spire-server --kubeconfig="${CLUSTER_A_KUBECONFIG}" --timeout=300s
kubectl rollout status statefulset spire-server -n spire-server --kubeconfig="${CLUSTER_B_KUBECONFIG}" --timeout=300s

kubectl exec -it spire-server-0 -n spire-server --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -- spire-server bundle set -format spiffe -id spiffe://"${CLUSTER_B}" -path /run/spire/config/fed-bundle

kubectl exec -it spire-server-0 -n spire-server --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 -- spire-server bundle set -format spiffe -id spiffe://"${CLUSTER_A}" -path /run/spire/config/fed-bundle


echo "cluster A:"
kubectl exec -it spire-server-0 -n spire-server --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -- spire-server bundle show

echo "cluster B:"
kubectl exec -it spire-server-0 -n spire-server --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 -- spire-server bundle show
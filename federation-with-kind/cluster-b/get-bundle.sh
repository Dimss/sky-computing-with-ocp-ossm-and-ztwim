kubectl exec -it spire-server-0 -n spire-server \
 -- spire-server bundle show -format spiffe > fed_bundle

kubectl create configmap spire-server -n spire-server \
  --from-file=fed-bundle=../cluster-a/fed_bundle \
  -o yaml --dry-run=client | kubectl apply -f -


kubectl exec -it spire-server-0 -n spire-server \
 -- spire-server bundle set -format spiffe -id spiffe://cluster-a -path /run/spire/config/fed-bundle

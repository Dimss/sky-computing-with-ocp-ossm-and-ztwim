kubectl cp ../cluster-a/cluster-a.bundle spire-server/spire-server-0:/tmp/cluster-a.bundle

kubectl exec -it spire-server-0 -n spire-server \
 -- spire-server bundle \
  set -format \
  spiffe -id spiffe://cluster-a \
  -path ../cluster-a/cluster-a.bundle


kubectl exec -it spire-server-0 -n spire-server -- "echo \"adsas\" > /tmp/a"
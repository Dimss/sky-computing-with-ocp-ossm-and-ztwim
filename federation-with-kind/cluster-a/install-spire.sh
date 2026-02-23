helm upgrade --install \
   -n spire-server spire-crds \
   spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ \
   --create-namespace
helm upgrade --install \
   -n spire-server spire \
    spire --repo https://spiffe.github.io/helm-charts-hardened/ \
    --set global.spire.trustDomain=cluster-a


# define base domain
export BASE_DOMAIN=$(kubectl get svc istio-gateway  -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)
# create Gateway CR
cat <<EOF | kubectl apply -f -
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
        number: 8443
        name: tls-passthrough
        protocol: TLS
      tls:
        mode: PASSTHROUGH
      hosts:
        - "spire-bundle.$BASE_DOMAIN"
EOF

cat <<EOF | kubectl apply -f -
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
      - port: 8443
        sniHosts:
        - "spire-bundle.$BASE_DOMAIN"
      route:
      - destination:
          host: spire-server.spire-server.svc.cluster.local
          port:
            number: 8443
EOF
source "$(dirname "$0")/01-define-exports.sh"
export JWT_ISSUER="https://oidc-discovery.$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
cat <<EOF | oc apply -f -
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: httpbin
  namespace: ${TPJ}
spec:
  selector:
    matchLabels:
      app: httpbin
  jwtRules:
    - issuer: "${JWT_ISSUER}"
      jwksUri: https://spire-spiffe-oidc-discovery-provider.${ZTWIM_NS}.svc/keys
      audiences:
      - sky-computing-demo
      forwardOriginalToken: true
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin
  namespace: ${TPJ}
spec:
  selector:
    matchLabels:
      app: httpbin
  rules:
    - from:
        - source:
            requestPrincipals: ["${JWT_ISSUER}/*"]
EOF

source "$(dirname "$0")/01-define-exports.sh"


kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: helloworld-waypoint
  namespace: sample
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: helloworld
  action: ALLOW
  rules:
    - when:
      - key: request.headers[x-foo]
        values: ["x-bar"]
EOF

kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: helloworld-waypoint
  namespace: sample
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: helloworld
  action: ALLOW
  rules:
    - when:
      - key: request.headers[x-foo]
        values: ["x-bar"]
EOF



#
#
#for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
#
#kubectl apply --kubeconfig="${kubeconfig}" -f - <<EOF
#apiVersion: networking.istio.io/v1
#kind: DestinationRule
#metadata:
#  name: sticky-session-dr
#  namespace: sample
#spec:
#  host: helloworld
#  trafficPolicy:
#    loadBalancer:
#      consistentHash:
#        httpCookie:
#          name: user-session
#          ttl: 3600s
#EOF
#
#done
#



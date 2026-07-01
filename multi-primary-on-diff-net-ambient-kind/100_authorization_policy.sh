source "$(dirname "$0")/01-define-exports.sh"


#kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f - <<EOF
#apiVersion: security.istio.io/v1
#kind: AuthorizationPolicy
#metadata:
#  name: helloworld-waypoint
#  namespace: sample
#spec:
#  targetRefs:
#  - kind: Service
#    group: ""
#    name: helloworld
#  action: ALLOW
#  rules:
#    - when:
#      - key: request.headers[x-foo]
#        values: ["x-bar"]
#EOF

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


#
#
#kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f - <<EOF
#apiVersion: security.istio.io/v1
#kind: AuthorizationPolicy
#metadata:
#  name: helloworld-waypoint
#  namespace: istio-system
#spec:
#  targetRefs:
#  - kind: Gateway
#    group: gateway.networking.k8s.io
#    name: helloworld-gateway
#  action: ALLOW
#  rules:
#    - when:
#      - key: request.headers[x-foo]
#        values: ["x-bar"]
#EOF




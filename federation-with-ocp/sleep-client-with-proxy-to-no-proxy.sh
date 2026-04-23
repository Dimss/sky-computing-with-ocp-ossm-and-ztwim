source "$(dirname "$0")/01-define-exports.sh"

export SAMPLE_NS=sample

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n test-1 -f -
apiVersion: v1
kind: Service
metadata:
  name: spiffe-validator
spec:
  selector:
    app: spiffe-mtls-validator
  ports:
    - protocol: TCP
      port: 8443
      targetPort: 8443
  type: LoadBalancer
EOF

cat <<EOF | oc apply -n ${SAMPLE_NS} --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: spiffe-validator
spec:
  hosts:
  - spiffe-validator.external
  addresses:
  - 10.0.146.46/32
  ports:
  - number: 8443
    name: tcp
    protocol: TCP
  location: MESH_INTERNAL
  resolution: STATIC
  endpoints:
  - address: "10.0.146.46"
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: spiffe-validator
spec:
  host: spiffe-validator.external
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: v1
kind: Service
metadata:
  name: sleep
  labels:
    app: sleep
    service: sleep
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: sleep
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
        spiffe.io/audience: "${SPIFFE_AUDIENCE}"
      labels:
        app: sleep
    spec:
      terminationGracePeriodSeconds: 0
      serviceAccountName: federation-test
      containers:
      - name: sleep
        image: docker.io/curlimages/curl:8.16.0
        command: ["/bin/sleep", "infinity"]
        imagePullPolicy: IfNotPresent
---
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: sample-sleep
spec:
  autoPopulateDNSNames: true
  className: zero-trust-workload-identity-manager-spire
  fallback: true
  federatesWith:
    - $CLUSTER_A
  hint: default
  podSelector:
    matchLabels:
      app: "sleep"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF
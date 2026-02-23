source "$(dirname "$0")/01-define-exports.sh"

export NAMESPACE=test-1

kubectl create namespace $NAMESPACE --kubeconfig="${CLUSTER_A_KUBECONFIG}"

export BASE_DOMAIN=$(kubectl get svc istio-gateway --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n istio-system -ojson  | jq -r .status.loadBalancer.ingress[].hostname)

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
spec:
  selector:
    istio: gateway
  servers:
    - port:
        number: 443
        name: tls-passthrough
        protocol: TLS
      tls:
        mode: PASSTHROUGH
      hosts:
        - "spiffe-mtls-validator.$BASE_DOMAIN"
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
spec:
  hosts:
    - "spiffe-mtls-validator.$BASE_DOMAIN"
  gateways:
    - spiffe-mtls-validator
  tls:
    - match:
      - port: 443
        sniHosts:
        - "spiffe-mtls-validator.$BASE_DOMAIN"
      route:
      - destination:
          host: spiffe-mtls-validator.$NAMESPACE.svc.cluster.local
          port:
            number: 8443
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
  labels:
    app: spiffe-mtls-validator
spec:
  selector:
    matchLabels:
      app: spiffe-mtls-validator
  template:
    metadata:
      labels:
        app: spiffe-mtls-validator
        spiffe.io/spire-managed-identity: "true"
    spec:
      serviceAccountName: spiffe-mtls-validator
      containers:
        - name: app
          image: docker.io/dimssss/spiffe-mtls-validator
          command: ["/bin/bash","-c","sleep inf"]
          securityContext:
            runAsUser: 0
            runAsGroup: 0
          volumeMounts:
            - name: spiffe-workload-api
              mountPath: /run/secrets/workload-spiffe-uds
              readOnly: true
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: /run/secrets/workload-spiffe-uds
      volumes:
        - name: spiffe-workload-api
          csi:
            driver: "csi.spiffe.io"
            readOnly: true
---
apiVersion: v1
kind: Service
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
  labels:
    app: spiffe-mtls-validator
spec:
  ports:
    - port: 8443
      name: http
  selector:
    app: spiffe-mtls-validator
---
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: spiffe-mtls-validator-server
spec:
  className: spire-server-spire
  fallback: true
  federatesWith:
    - cluster-b
  hint: default
  podSelector:
    matchLabels:
      app: "spiffe-mtls-validator"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF


kubectl create namespace $NAMESPACE --kubeconfig="${CLUSTER_B_KUBECONFIG}"

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spiffe-mtls-client
  namespace: $NAMESPACE
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spiffe-mtls-client
  namespace: $NAMESPACE
  labels:
    app: spiffe-mtls-client
spec:
  selector:
    matchLabels:
      app: spiffe-mtls-client
  template:
    metadata:
      labels:
        app: spiffe-mtls-client
        spiffe.io/spire-managed-identity: "true"
    spec:
      serviceAccountName: spiffe-mtls-client
      containers:
        - name: app
          image: docker.io/dimssss/spiffe-mtls-validator
          command: ["/bin/bash","-c","sleep inf"]
          securityContext:
            runAsUser: 0
            runAsGroup: 0
          volumeMounts:
            - name: spiffe-workload-api
              mountPath: /run/secrets/workload-spiffe-uds
              readOnly: true
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: /run/secrets/workload-spiffe-uds
      volumes:
        - name: spiffe-workload-api
          csi:
            driver: "csi.spiffe.io"
            readOnly: true
---
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: spiffe-mtls-client
spec:
  className: spire-server-spire
  fallback: true
  federatesWith:
    - cluster-a
  hint: default
  podSelector:
    matchLabels:
      app: "spiffe-mtls-client"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF
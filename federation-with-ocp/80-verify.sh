source "$(dirname "$0")/01-define-exports.sh"

export NAMESPACE=test-1

kubectl create namespace $NAMESPACE --kubeconfig="${CLUSTER_A_KUBECONFIG}"

oc adm policy add-scc-to-user privileged system:serviceaccount:$NAMESPACE:spiffe-mtls-validator --kubeconfig="${CLUSTER_A_KUBECONFIG}"

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
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
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: spiffe-mtls-validator
  namespace: $NAMESPACE
spec:
  host: $VALIDATOR_DOMAIN_CLUSTER_A
  port:
    targetPort: http
  tls:
    termination: passthrough
  to:
    kind: Service
    name: spiffe-mtls-validator
    weight: 100
---
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: spiffe-mtls-validator-server
spec:
  className: zero-trust-workload-identity-manager-spire
  fallback: true
  federatesWith:
    - $CLUSTER_B
  hint: default
  podSelector:
    matchLabels:
      app: "spiffe-mtls-validator"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF


kubectl create namespace $NAMESPACE --kubeconfig="${CLUSTER_B_KUBECONFIG}"

oc adm policy add-scc-to-user privileged system:serviceaccount:$NAMESPACE:spiffe-mtls-client --kubeconfig="${CLUSTER_B_KUBECONFIG}"



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
  className: zero-trust-workload-identity-manager-spire
  fallback: true
  federatesWith:
    - $CLUSTER_A
  hint: default
  podSelector:
    matchLabels:
      app: "spiffe-mtls-client"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF
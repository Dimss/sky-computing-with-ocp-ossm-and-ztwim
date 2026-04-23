source "$(dirname "$0")/01-define-exports.sh"

export SAMPLE_NS=sample

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

  kubectl create \
   --kubeconfig="${kubeconfig}" \
   namespace ${SAMPLE_NS}

  kubectl label \
   --kubeconfig="${kubeconfig}" \
    namespace ${SAMPLE_NS} istio-injection=enabled

cat <<EOF | oc apply -n ${SAMPLE_NS} --kubeconfig="${kubeconfig}" -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: cross-network-gateway
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
EOF
done

cat <<EOF | oc apply -n ${SAMPLE_NS} --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: federation-test
---
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
    service: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-v1
  labels:
    app: helloworld
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
      version: v1
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
        spiffe.io/audience: "${SPIFFE_AUDIENCE}"
      labels:
        app: helloworld
        version: v1
    spec:
      serviceAccountName: federation-test
      containers:
      - name: helloworld
        image: docker.io/istio/examples-helloworld-v1:1.0
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent #Always
        ports:
        - containerPort: 5000
---
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: sample-helloworld
spec:
  autoPopulateDNSNames: true
  className: zero-trust-workload-identity-manager-spire
  fallback: true
  federatesWith:
    - $CLUSTER_A
  hint: default
  podSelector:
    matchLabels:
      app: "helloworld"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF

cat <<EOF | oc apply -n ${SAMPLE_NS} --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
    service: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: federation-test
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
    - $CLUSTER_B
  hint: default
  podSelector:
    matchLabels:
      app: "sleep"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF



cat <<EOF | oc apply -n ${SAMPLE_NS} --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
    service: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: federation-test
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
    - $CLUSTER_B
  hint: default
  podSelector:
    matchLabels:
      app: "sleep"
  spiffeIDTemplate: spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{.PodSpec.ServiceAccountName }}
EOF


POD=$(oc get pod --kubeconfig="${CLUSTER_B_KUBECONFIG}" -n "${SAMPLE_NS}" -l app=helloworld -n sample -o jsonpath="{.items[0].metadata.name}")
istioctl proxy-config --kubeconfig="${CLUSTER_B_KUBECONFIG}" -n "${SAMPLE_NS}" secret "$POD" \
 -n sample -o json \
 | jq -r  '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' \
 | base64  --decode > chain.pem
openssl x509 -in chain.pem -text | grep SPIRE



POD=$(oc get pod --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n "${SAMPLE_NS}" -l app=sleep -n sample -o jsonpath="{.items[0].metadata.name}")
istioctl proxy-config --kubeconfig="${CLUSTER_A_KUBECONFIG}" -n "${SAMPLE_NS}" secret "$POD" \
 -n sample -o json \
 | jq -r  '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' \
 | base64  --decode > chain.pem
openssl x509 -in chain.pem -text | grep SPIRE
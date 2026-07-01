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
      labels:
        app: helloworld
        version: v1
    spec:
      containers:
      - name: helloworld
        image: docker.io/istio/examples-helloworld-v1:1.0
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent #Always
        ports:
        - containerPort: 5000
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
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: docker.io/curlimages/curl:8.16.0
        command: ["/bin/sleep", "infinity"]
        imagePullPolicy: IfNotPresent
EOF

kubectl exec deploy/sleep \
  -n sample \
  --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  -- curl -sS helloworld.sample:5000/hello

istioctl proxy-config clusters deployment/sleep.sample --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  --fqdn helloworld.sample.svc.cluster.local -ojson | \
   jq .[0].transportSocketMatches.[0].transportSocket.typedConfig.commonTlsContext.combinedValidationContext.defaultValidationContext.matchSubjectAltNames
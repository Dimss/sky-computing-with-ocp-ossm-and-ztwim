source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

oc create ns istio-system --kubeconfig=$kubeconfig

if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_A
  export LOCAL_TRUST_DOMAIN=$CLUSTER_A
  export LOCAL_BUNDLE_URL=$FEDERATION_ENDPOINT_CLUSTER_A
  export REMOTE_TRUST_DOMAIN=$CLUSTER_B
  export REMOTE_BUNDLE_URL="$FEDERATION_ENDPOINT_CLUSTER_B"
else
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_B
  export LOCAL_TRUST_DOMAIN=$CLUSTER_B
  export LOCAL_BUNDLE_URL="$FEDERATION_ENDPOINT_CLUSTER_B"
  export REMOTE_TRUST_DOMAIN=$CLUSTER_A
  export REMOTE_BUNDLE_URL="$FEDERATION_ENDPOINT_CLUSTER_A"
fi

echo "ISTIO_TRUST_DOMAIN_NAME: $ISTIO_TRUST_DOMAIN_NAME"
echo "ISTIO_MULTI_CLUSTER_NAME: $ISTIO_MULTI_CLUSTER_NAME"
echo "ISTIO_MULTI_CLUSTER_NETWORK: $ISTIO_MULTI_CLUSTER_NETWORK"
echo "LOCAL_TRUST_DOMAIN $LOCAL_TRUST_DOMAIN"
echo "LOCAL_TRUST_DOMAIN: $LOCAL_BUNDLE_URL"
echo "REMOTE_TRUST_DOMAIN: $REMOTE_TRUST_DOMAIN"
echo "REMOTE_BUNDLE_URL: $REMOTE_BUNDLE_URL"

cat <<EOF | kubectl apply --kubeconfig="${kubeconfig}" -f -
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: InPlace
  values:
    meshConfig:
      trustDomain: $ISTIO_TRUST_DOMAIN_NAME
      defaultConfig:
        proxyMetadata:
          WORKLOAD_IDENTITY_SOCKET_FILE: "spire-agent.sock"
      caCertificates:
      - spiffeBundleUrl: $LOCAL_BUNDLE_URL
        trustDomains:
        - $LOCAL_TRUST_DOMAIN
      - spiffeBundleUrl: $REMOTE_BUNDLE_URL
        trustDomains:
        - $REMOTE_TRUST_DOMAIN
    global:
      meshID: $ISTIO_MESH_ID
      multiCluster:
        clusterName: $ISTIO_MULTI_CLUSTER_NAME
      network: $ISTIO_MULTI_CLUSTER_NETWORK
    sidecarInjectorWebhook:
      templates:
        spire: |
          spec:
            initContainers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
        spireGw: |
          spec:
            containers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
EOF
done

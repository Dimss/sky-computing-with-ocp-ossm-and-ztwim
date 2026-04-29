source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

helm upgrade --install sail-operator \
  sail-operator/sail-operator \
  -n istio-system \
  --create-namespace \
  --kubeconfig="${kubeconfig}"

  kubectl create namespace istio-cni --kubeconfig="${kubeconfig}"
  kubectl label namespace default istio-injection=enabled --kubeconfig="${kubeconfig}"

cat <<EOF | kubectl --kubeconfig="${kubeconfig}" apply -f -
apiVersion: sailoperator.io/v1
kind: IstioCNI
metadata:
  name: default
spec:
  namespace: istio-cni
EOF

if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_A
  export ISTIO_TRUST_DOMAIN_NAME_ALIAS=$CLUSTER_B
else
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_B
  export ISTIO_TRUST_DOMAIN_NAME_ALIAS=$CLUSTER_A
fi

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
      trustDomainAliases:
      - $ISTIO_TRUST_DOMAIN_NAME_ALIAS
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

source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do
  kubectl create namespace ztunnel --kubeconfig="${kubeconfig}"
done

oc apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f - <<EOF
apiVersion: sailoperator.io/v1
kind: ZTunnel
metadata:
  name: default
spec:
  namespace: ztunnel
  values:
    ztunnel:
      multiCluster:
        clusterName: $CLUSTER_A
      network: $NETWORK_A
EOF

oc apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f - <<EOF
apiVersion: sailoperator.io/v1
kind: ZTunnel
metadata:
  name: default
spec:
  namespace: ztunnel
  values:
    ztunnel:
      multiCluster:
        clusterName: $CLUSTER_B
      network: $NETWORK_B
EOF



source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | istioctl install -y --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: $CLUSTER_B
      network: $NETWORK_B
EOF

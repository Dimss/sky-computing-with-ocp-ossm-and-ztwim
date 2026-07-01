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

kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/helloworld/helloworld.yaml" \
  -l service=helloworld -n sample
kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/helloworld/helloworld.yaml" \
  -l version=v1 -n sample
kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml" -n sample


kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/helloworld/helloworld.yaml" \
  -l service=helloworld -n sample
kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/helloworld/helloworld.yaml" \
  -l version=v2 -n sample
kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  -f "https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml" -n sample



for i in {0..9}; do
  kubectl exec -n sample -c sleep \
    "$(kubectl get pod -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello;
done
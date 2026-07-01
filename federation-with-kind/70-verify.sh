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

# Create the HelloWorld service in Clusters A
kubectl apply \
 -n ${SAMPLE_NS} \
 --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/helloworld/helloworld.yaml \
 -l service=helloworld

# Deploy curl application
kubectl apply \
 -n ${SAMPLE_NS} \
 --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/sleep/sleep.yaml

# Create the HelloWorld service in Cluster B
kubectl apply \
 -n ${SAMPLE_NS} \
 --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/helloworld/helloworld.yaml \
 -l service=helloworld

# Deploy HelloWorld application in Cluster B
kubectl apply \
 -n ${SAMPLE_NS} \
 --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 -f https://raw.githubusercontent.com/istio/istio/refs/heads/master/samples/helloworld/helloworld.yaml \
 -l version=v1

# Add spire injection template to curl application in Cluster A
kubectl patch deploy sleep \
    -n ${SAMPLE_NS} \
    --type='merge' \
    --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
    -p '{"spec": {"template": {"metadata": {"annotations": {"inject.istio.io/templates": "sidecar,spire"}}}}}'

# Add spire injection template to HelloWorld application in Cluster B
kubectl patch deploy helloworld-v1 \
   -n ${SAMPLE_NS} \
   --type='merge' \
   --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
    -p '{"spec": {"template": {"metadata": {"annotations": {"inject.istio.io/templates": "sidecar,spire"}}}}}'

# Wait till both deployment are up and running
kubectl rollout status deploy/sleep --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n ${SAMPLE_NS} --timeout=300s
kubectl rollout status deploy/helloworld-v1 --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n ${SAMPLE_NS} --timeout=300s

kubectl exec deploy/sleep \
  -n sample \
  --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  -- curl -sS helloworld.sample:5000/hello


#
#
#istioctl proxy-config clusters deployment/sleep.sample --kubeconfig=${CLUSTER_A_KUBECONFIG} \
#  --fqdn helloworld.sample.svc.cluster.local -ojson | \
#   jq .[0].transportSocketMatches.[0].transportSocket.typedConfig.commonTlsContext.combinedValidationContext.defaultValidationContext.matchSubjectAltNames
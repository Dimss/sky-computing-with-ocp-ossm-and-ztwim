source "$(dirname "$0")/01-define-exports.sh"
export SAMPLE_NS=sample

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

  kubectl create \
   --kubeconfig="${kubeconfig}" \
   namespace ${SAMPLE_NS}

  kubectl label \
   --kubeconfig="${kubeconfig}" \
   namespace sample \
   istio.io/dataplane-mode=ambient

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

kubectl label --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
 svc helloworld -n sample istio.io/global="true"

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

kubectl label --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 svc helloworld -n sample istio.io/global="true"


# Wait till both deployment are up and running
kubectl rollout status deploy/sleep --kubeconfig "${CLUSTER_A_KUBECONFIG}" -n ${SAMPLE_NS} --timeout=300s
kubectl rollout status deploy/helloworld-v1 --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n ${SAMPLE_NS} --timeout=300s

kubectl exec deploy/sleep \
  -n sample \
  --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  -- curl -sS helloworld.sample:5000/hello



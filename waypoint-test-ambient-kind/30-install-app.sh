source "$(dirname "$0")/01-define-exports.sh"
export SAMPLE_NS=sample


kubectl create \
 --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 namespace ${SAMPLE_NS}

kubectl label \
 --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
 namespace sample \
 istio.io/dataplane-mode=ambient


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

kubectl rollout status deploy/helloworld-v1 --kubeconfig "${CLUSTER_B_KUBECONFIG}" -n ${SAMPLE_NS} --timeout=300s





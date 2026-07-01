source "$(dirname "$0")/01-define-exports.sh"


echo "--> Should FAIL"
for i in {1..5}; do
kubectl exec deploy/sleep \
  -n sample \
  --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  -- curl -sS -H "x-foo: x-bar1"  helloworld.sample:5000/hello
done

echo "--> Should PASS"

for i in {1..5}; do
kubectl exec deploy/sleep \
  -n sample \
  --kubeconfig=${CLUSTER_A_KUBECONFIG} \
  -- curl -sS -H "x-foo: x-bar"  helloworld.sample:5000/hello
done


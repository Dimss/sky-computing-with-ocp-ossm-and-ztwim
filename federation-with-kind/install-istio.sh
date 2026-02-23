helm repo add sail-operator https://istio-ecosystem.github.io/sail-operator
helm repo update
helm install sail-operator \
  sail-operator/sail-operator \
  -n istio-system \
  --create-namespace

helm repo add istio https://istio-release.storage.googleapis.com/charts
# update the repo
helm repo update
# install the istio gateway helm chart
helm install istio-gateway -n istio-system \
  istio/gateway

kubectl create ns istio-cni

cat <<EOF | kubectl apply -f -
apiVersion: sailoperator.io/v1
kind: IstioCNI
metadata:
  name: default
spec:
  namespace: istio-cni
EOF

cat <<EOF | kubectl apply -f -
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: InPlace
EOF


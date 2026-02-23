source "$(dirname "$0")/01-define-exports.sh"

kubectl create namespace "${NIPIP_LB_NAMESPACE}" --kubeconfig="${CLUSTER_A_KUBECONFIG}"

kubectl create namespace "${NIPIP_LB_NAMESPACE}" --kubeconfig="${CLUSTER_B_KUBECONFIG}"

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: niplb
  namespace: ${NIPIP_LB_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: niplb
rules:
  - apiGroups: [ "" ]
    resources: [ "services" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: [ "" ]
    resources: ["services/status"]
    verbs: ["update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: niplb
subjects:
  - kind: ServiceAccount
    name: niplb
    namespace: ${NIPIP_LB_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: niplb
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: niplb
  namespace: ${NIPIP_LB_NAMESPACE}
  labels:
    app: niplb
spec:
  selector:
    matchLabels:
      app: niplb
  template:
    metadata:
      labels:
        app: niplb
    spec:
      serviceAccountName: niplb
      containers:
        - name: niplb
          image: docker.io/dimssss/niplb:latest
          command:
            - /usr/local/bin/niplb
            - --nip-ip=${NIPIP_LB_IP}
            - --domain-prefix=${CLUSTER_A}
          imagePullPolicy: Always
          resources:
            requests:
              cpu: "50m"
              memory: "50"
EOF

cat <<EOF | kubectl apply --kubeconfig="${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: niplb
  namespace: ${NIPIP_LB_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: niplb
rules:
  - apiGroups: [ "" ]
    resources: [ "services" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: [ "" ]
    resources: ["services/status"]
    verbs: ["update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: niplb
subjects:
  - kind: ServiceAccount
    name: niplb
    namespace: ${NIPIP_LB_NAMESPACE}
roleRef:
  kind: ClusterRole
  name: niplb
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: niplb
  namespace: ${NIPIP_LB_NAMESPACE}
  labels:
    app: niplb
spec:
  selector:
    matchLabels:
      app: niplb
  template:
    metadata:
      labels:
        app: niplb
    spec:
      serviceAccountName: niplb
      containers:
        - name: niplb
          image: docker.io/dimssss/niplb:latest
          command:
            - /usr/local/bin/niplb
            - --nip-ip=${NIPIP_LB_IP}
            - --domain-prefix=${CLUSTER_B}
          imagePullPolicy: Always
          resources:
            requests:
              cpu: "50m"
              memory: "50"
EOF
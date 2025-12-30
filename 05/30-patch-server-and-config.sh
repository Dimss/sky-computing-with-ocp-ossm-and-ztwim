source "$(dirname "$0")/01-define-exports.sh"

kubectl patch statefulset spire-server -n "${ZTWIM_NS}" --patch '
spec:
  template:
    spec:
      volumes:
      - name: x509pop-ca
        secret:
          secretName: x509pop-ca
      containers:
      - name: spire-server
        volumeMounts:
        - name: x509pop-ca
          mountPath: /tmp/x509pop-ca
          readOnly: true
'

kubectl get configmap spire-server -n "${ZTWIM_NS}" -o json | \

jq --argjson new "$NEW_ATTESTOR" \
   '.data["server.conf"] |= (fromjson |
    if (.plugins.NodeAttestor | any(has("x509pop")))
    then .
    else .plugins.NodeAttestor += [$new]
    end | tojson)' | \
kubectl apply -f -


kubectl rollout restart statefulset spire-server -n "${ZTWIM_NS}"

kubectl rollout status statefulset/spire-server -n "${ZTWIM_NS}" --timeout=300s
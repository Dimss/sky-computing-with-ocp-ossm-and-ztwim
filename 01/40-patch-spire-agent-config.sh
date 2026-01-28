source "$(dirname "$0")/01-define-exports.sh"

export JQ_PATCH="{data: {\"agent.conf\": (.data.\"agent.conf\" | fromjson | .agent.socket_path = \"/tmp/spire-agent/public/socket\" | .agent.admin_socket_path = \"/tmp/spire-agent-admin-socket/admin/socket\" | .agent.authorized_delegates = [\"spiffe://${TRUST_DOMAIN}/ns/default/sa/spire-delegated-identity-api\"] | tostring)}}"

oc patch \
  configmap spire-agent -n "${ZTWIM_NS}" \
  -p "$(oc get configmap spire-agent  \
  -n "${ZTWIM_NS}" -o json | \
  jq "$JQ_PATCH")"

oc rollout restart daemonset/spire-agent -n "${ZTWIM_NS}"
kubectl rollout status daemonset/spire-agent -n "${ZTWIM_NS}" --timeout=300s

## Check if admin socket volume already exists
if ! oc get daemonset spire-agent -n "${ZTWIM_NS}" -o jsonpath='{.spec.template.spec.volumes[?(@.name=="spire-agent-admin-socket-dir")].name}' | grep -q "spire-agent-admin-socket-dir"; then
  echo "Adding admin socket volume to daemonset..."
  oc patch daemonset spire-agent -n "${ZTWIM_NS}" --type='json' -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/-",
      "value": {
        "hostPath": {
          "path": "/run/spire/agent-admin-sockets",
          "type": "DirectoryOrCreate"
        },
        "name": "spire-agent-admin-socket-dir"
      }
    }
  ]'
else
  echo "Admin socket volume already exists, skipping..."
fi
#
## Check if admin socket volumeMount already exists
if ! oc get daemonset spire-agent -n "${ZTWIM_NS}" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="spire-agent-admin-socket-dir")].name}' | grep -q "spire-agent-admin-socket-dir"; then
  echo "Adding admin socket volumeMount to spire-agent container..."
  oc patch daemonset spire-agent -n "${ZTWIM_NS}" --type='json' -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/-",
      "value": {
        "mountPath": "/tmp/spire-agent-admin-socket/admin",
        "name": "spire-agent-admin-socket-dir"
      }
    }
  ]'
else
  echo "Admin socket volumeMount already exists, skipping..."
fi
#
oc rollout restart daemonset/spire-agent -n "${ZTWIM_NS}"
kubectl rollout status daemonset/spire-agent -n "${ZTWIM_NS}" --timeout=300s

source "$(dirname "$0")/01-define-exports.sh"

#oc patch \
#  configmap spire-agent -n "${ZTWIM_NS}" \
#  -p "$(oc get configmap spire-agent  \
#  -n "${ZTWIM_NS}" -o json | \
#  jq '{data: {"agent.conf": (.data."agent.conf" | fromjson | .agent.socket_path = "/tmp/spire-agent/public/socket" | tostring)}}')"

#oc rollout restart daemonset/spire-agent -n "${ZTWIM_NS}"
#kubectl rollout status daemonset/spire-agent -n "${ZTWIM_NS}" --timeout=300s

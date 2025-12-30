source "$(dirname "$0")/01-define-exports.sh"

CURL_POD=$(oc get pod -l app=curl -n "${TPJ}" -o jsonpath="{.items[0].metadata.name}")

oc exec "${CURL_POD}" -n "${TPJ}" -it -- curl http://httpbin
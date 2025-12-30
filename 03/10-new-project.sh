source "$(dirname "$0")/01-define-exports.sh"
oc create namespace "${TPJ}" 2>/dev/null  || oc project "${TPJ}"
oc label namespace "${TPJ}" istio-injection=enabled
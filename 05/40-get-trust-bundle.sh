source "$(dirname "$0")/01-define-exports.sh"

oc exec spire-server-0 \
 -c spire-server \
 -n "${ZTWIM_NS}" \
 -- /bin/sh -c "/spire-server bundle show -format pem > /tmp/bundle.crt"

oc cp "${ZTWIM_NS}"/spire-server-0:/tmp/bundle.crt "$(dirname "$0")/data/bundle.crt"

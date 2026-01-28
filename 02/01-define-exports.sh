source "$(dirname "$0")/../01/01-define-exports.sh"
export OSSM_NS=istio-system
export OSSM_CNI=istio-cni
export EXTRA_ROOT_CA="$(oc get secret oidc-serving-cert \
                         -n ${ZTWIM_NS} -o json | \
                         jq -r '.data."tls.crt"' | \
                         base64 -d | \
                         sed 's/^/        /')"
export VERIFY_NS=verify-ossm-ztwim

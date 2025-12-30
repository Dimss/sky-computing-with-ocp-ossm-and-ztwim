source "$(dirname "$0")/../01/01-define-exports.sh"
source "$(dirname "$0")/../02/01-define-exports.sh"
export SPIFFE_AUDIENCE="sky-computing-demo"
export TPJ=test-ossm-with-ztwim
export ZTWIM_NS=zero-trust-workload-identity-manager
export ODIC_DISCOVER_ROUTE=spire-oidc-discovery-provider
export ODIC_PROVIDER_URL=$(oc get route \
                            "${ODIC_DISCOVER_ROUTE}" \
                            -n "${ZTWIM_NS}" \
                            -o json | \
                            jq -r  .spec.host)
export FINGERPRINT=$(openssl s_client -servername "${ODIC_PROVIDER_URL}" -showcerts -connect "${ODIC_PROVIDER_URL}":443 < /dev/null 2>/dev/null \
     | awk '/BEGIN/,/END/{ if(/BEGIN/){a=""}; a=a$0"\n"; } END{print a}' \
     | openssl x509 -noout -fingerprint -sha1 \
     | cut -d= -f2 \
     | tr -d ':')
export AWS_BUILD_IN_POLICY=AmazonDynamoDBFullAccess
export ROLE_NAME="SkyComputingDemo2DynamoDBFullAccess"
export AUDIENCE="sky-computing-demo"
source "$(dirname "$0")/01-define-exports.sh"
export TPJ=test-ossm-with-ztwim
export VM_IP=$(curl -s ifconfig.io)
PSQL_POD=$(kubectl get pod -lapp=psql -n ${TPJ} -o jsonpath="{.items[0].metadata.name}")
PSQL_COMMAND="PGPASSWORD=test psql -h ${VM_IP} -U postgres -c '\\l'"
oc exec "${PSQL_POD}" -n ${TPJ} -- /bin/bash -c "${PSQL_COMMAND}"

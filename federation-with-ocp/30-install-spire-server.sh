source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply --kubeconfig "${CLUSTER_A_KUBECONFIG}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireServer
metadata:
  name: cluster
spec:
  logLevel: "info"
  logFormat: "text"
  jwtIssuer: $JWT_ISSUER_CLUSTER_A
  caValidity: "24h"
  defaultX509Validity: "1h"
  defaultJWTValidity: "5m"
  jwtKeyType: "rsa-2048"
  federation:
    bundleEndpoint:
      profile: https_spiffe
      refreshHint: 300
    managedRoute: "true"
  caSubject:
    country: "US"
    organization: "Sky Computing Corporation Site A"
    commonName: "SPIRE Server CA"
  persistence:
    size: "5Gi"
    accessMode: "ReadWriteOnce"
  datastore:
    databaseType: "sqlite3"
    connectionString: "/run/spire/data/datastore.sqlite3"
    tlsSecretName: ""
    maxOpenConns: 100
    maxIdleConns: 10
    connMaxLifetime: 0
    disableMigration: "false"
EOF

oc rollout restart statefulset/spire-server -n "${ZTWIM_NS}" --kubeconfig "${CLUSTER_A_KUBECONFIG}"

oc rollout status statefulset/spire-server -n "${ZTWIM_NS}" --timeout=300s --kubeconfig "${CLUSTER_A_KUBECONFIG}"

cat <<EOF | oc apply --kubeconfig "${CLUSTER_B_KUBECONFIG}" -f -
apiVersion: operator.openshift.io/v1alpha1
kind: SpireServer
metadata:
  name: cluster
spec:
  logLevel: "info"
  logFormat: "text"
  jwtIssuer: $JWT_ISSUER_CLUSTER_B
  caValidity: "24h"
  defaultX509Validity: "1h"
  defaultJWTValidity: "5m"
  jwtKeyType: "rsa-2048"
  federation:
    bundleEndpoint:
      profile: https_spiffe
      refreshHint: 300
    managedRoute: "true"
  caSubject:
    country: "US"
    organization: "Sky Computing Corporation Site B"
    commonName: "SPIRE Server CA"
  persistence:
    size: "5Gi"
    accessMode: "ReadWriteOnce"
  datastore:
    databaseType: "sqlite3"
    connectionString: "/run/spire/data/datastore.sqlite3"
    tlsSecretName: ""
    maxOpenConns: 100
    maxIdleConns: 10
    connMaxLifetime: 0
    disableMigration: "false"
EOF

oc rollout restart statefulset/spire-server -n "${ZTWIM_NS}" --kubeconfig "${CLUSTER_B_KUBECONFIG}"

oc rollout status statefulset/spire-server -n "${ZTWIM_NS}" --timeout=300s --kubeconfig "${CLUSTER_B_KUBECONFIG}"

source "$(dirname "$0")/01-define-exports.sh"

cat <<EOF | oc apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: curl-ext-authz-sidecar
  namespace: ${TPJ}
spec:
  workloadSelector:
    labels:
      app: curl
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_OUTBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
              subFilter:
                name: "envoy.filters.http.router"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.ext_authz
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
            transport_api_version: V3
            failure_mode_allow: false
            grpc_service:
              google_grpc:
                target_uri: 127.0.0.1:9010
                stat_prefix: "ext_authz"
              timeout: 0.5s
            include_peer_certificate: true
EOF

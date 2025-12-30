source "$(dirname "$0")/01-define-exports.sh"


cat << EOF > "$(dirname "$0")/data/agent.conf"
agent {
    data_dir = "/tmp/data"
    log_level = "DEBUG"
    server_address = "${SPIRE_SERVER_DOMAIN}"
    server_port = "443"
    socket_path ="/tmp/spire-agent/socket"
    trust_bundle_path = "/opt/spire/data/bundle.crt"
    trust_domain = "sky.computing.ocp.one"
}

plugins {
    NodeAttestor "x509pop" {
        plugin_data {
            private_key_path = "/opt/spire/data/${LEGACY_DB_SRV}.key.pem"
            certificate_path = "/opt/spire/data/${LEGACY_DB_SRV}.crt.pem"
        }
    }
    KeyManager "disk" {
        plugin_data {
            directory = "data"
        }
    }
    WorkloadAttestor "unix" {
        plugin_data {
        }
    }
}
EOF

cat << EOF > "$(dirname "$0")/config.yaml"
node:
  id: "pg-reverse-proxy"
  cluster: "envoy-cluster-with-spire"
static_resources:
  listeners:
    - name: ingress_postgres_mtls
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 5432
      filter_chains:
        - filters:
            - name: envoy.filters.network.tcp_proxy
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                stat_prefix: postgres_tcp
                cluster: postgresql_service
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              require_client_certificate: true
              common_tls_context:
                tls_certificate_sds_secret_configs:
                  - name: "${WORKLOAD_SPIFFE_ID}"
                    sds_config:
                      resource_api_version: V3
                      api_config_source:
                        api_type: GRPC
                        transport_api_version: V3
                        grpc_services:
                          envoy_grpc:
                            cluster_name: spire_agent
                validation_context_sds_secret_config:
                  name: "spiffe://${TRUST_DOMAIN}"
                  sds_config:
                    resource_api_version: V3
                    api_config_source:
                      api_type: GRPC
                      transport_api_version: V3
                      grpc_services:
                        envoy_grpc:
                          cluster_name: spire_agent
  clusters:
    - name: spire_agent
      connect_timeout: 0.25s
      http2_protocol_options: {}
      load_assignment:
        cluster_name: spire_agent
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    pipe:
                      path: /tmp/spire-agent/socket
    - name: postgresql_service
      connect_timeout: 1s
      type: STATIC
      load_assignment:
        cluster_name: postgresql_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: 127.0.0.1
                      port_value: 7432
EOF



podman pod rm \
  spire-agent-envoy-pod \
  --force 2>/dev/null \
  && podman pod create \
  --name spire-agent-envoy-pod \
  --share pid,net,ipc,uts \
  -p 5432:5432

podman volume rm --force spire-socket 2>/dev/null \
  && podman volume create spire-socket

podman run -d --pod spire-agent-envoy-pod \
  -v spire-socket:/tmp/spire-agent \
  -v "./$(dirname "$0")/data":/opt/spire/data \
  -v spire-socket:/tmp/spire-agent \
  ghcr.io/spiffe/spire-agent:1.14.0 \
  -config /opt/spire/data/agent.conf

podman run -d --pod spire-agent-envoy-pod \
  -v spire-socket:/tmp/spire-agent \
  -v "./$(dirname "$0")/config.yaml":/etc/envoy/envoy.yaml \
  docker.io/envoyproxy/envoy:v1.36.2 \
  -c /etc/envoy/envoy.yaml \
  --component-log-level upstream:debug,connection:debug,filter:debug

podman run -d \
   --pod spire-agent-envoy-pod \
   -e POSTGRES_PASSWORD=test \
   -e PGPORT=7432 \
   postgres:16.9




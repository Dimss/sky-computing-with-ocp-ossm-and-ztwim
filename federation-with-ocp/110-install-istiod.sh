source "$(dirname "$0")/01-define-exports.sh"

for kubeconfig in "${CLUSTER_A_KUBECONFIG}" "${CLUSTER_B_KUBECONFIG}"; do

echo "${kubeconfig}"

oc new-project --kubeconfig="${kubeconfig}" "${OSSM_NS}"


if [[ "${kubeconfig}" == *"cluster-a"* ]]; then
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_A
  export ISTIO_TRUST_DOMAIN_NAME_ALIAS=$CLUSTER_B
  export ISTIO_MESH_ID=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_A
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_A
  export EXTRA_ROOT_CA="$(oc get secret --kubeconfig="${kubeconfig}" oidc-serving-cert \
                           -n ${ZTWIM_NS} -o json | \
                           jq -r '.data."tls.crt"' | \
                           base64 -d | \
                           sed 's/^/        /')"
else
  export ISTIO_TRUST_DOMAIN_NAME=$CLUSTER_B
  export ISTIO_TRUST_DOMAIN_NAME_ALIAS=$CLUSTER_A
  export ISTIO_MESH_ID=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NAME=$CLUSTER_B
  export ISTIO_MULTI_CLUSTER_NETWORK=$NETWORK_B
  export EXTRA_ROOT_CA="$(oc get secret --kubeconfig="${kubeconfig}" oidc-serving-cert \
                           -n ${ZTWIM_NS} -o json | \
                           jq -r '.data."tls.crt"' | \
                           base64 -d | \
                           sed 's/^/        /')"
fi

# Create Istiod
cat <<EOF | oc apply --kubeconfig="${kubeconfig}" -f -
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: InPlace
  values:
    pilot:
      jwksResolverExtraRootCA: |
${EXTRA_ROOT_CA}
      env:
        PILOT_JWT_ENABLE_REMOTE_JWKS: "true"
    global:
      meshID: $ISTIO_MESH_ID
      multiCluster:
        clusterName: $ISTIO_MULTI_CLUSTER_NAME
      network: $ISTIO_MULTI_CLUSTER_NETWORK
    meshConfig:
      defaultConfig:
        proxyMetadata:
          WORKLOAD_IDENTITY_SOCKET_FILE: "spire-agent.sock"
      trustDomain: $ISTIO_TRUST_DOMAIN_NAME
      trustDomainAliases:
      - $ISTIO_TRUST_DOMAIN_NAME_ALIAS
    sidecarInjectorWebhook:
      templates:
        spireGw: |
          spec:
            containers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
        spire: |
          spec:
            initContainers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            - name: spiffe-iam-broker
              image: dimssss/spiffe-iam-broker:latest
              args:
              - aws
              restartPolicy: Always
              ports:
              - containerPort: 9876
                name: broker-http
              env:
              - name: SPIFFE_IAM_BROKER_AUDIENCE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['spiffe.io/audience']
              - name: SPIFFE_IAM_BROKER_ROLE_ARN
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['spiffe.io/roleArn']
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            - name: envoy-jwt-auth-helper
              image: dimssss/envoy-jwt-auth-helper:latest
              restartPolicy: Always
              env:
              - name: SPIRE_ENVOY_JWT_HELPER_AUDIENCE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.annotations['spiffe.io/audience']
              - name: SPIRE_ENVOY_JWT_HELPER_JWT_MODE
                value: jwt_injection
              - name: SPIRE_ENVOY_JWT_HELPER_SOCKET_PATH
                value: unix:///run/secrets/workload-spiffe-uds/spire-agent.sock
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
EOF
# Wait till it successfully installed
until oc get deployment istiod --kubeconfig="${kubeconfig}" -n "${OSSM_NS}" &> /dev/null; do sleep 3; done
oc wait --for=condition=Available deployment/istiod --kubeconfig="${kubeconfig}" -n "${OSSM_NS}" --timeout=300s
done
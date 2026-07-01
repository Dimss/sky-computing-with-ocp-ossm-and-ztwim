source "$(dirname "$0")/01-define-exports.sh"

openssl genrsa -out root-key.pem 4096
cat <<EOF > root-ca.conf
[ req ]
encrypt_key = no
prompt = no
utf8 = yes
default_md = sha256
default_bits = 4096
req_extensions = req_ext
x509_extensions = req_ext
distinguished_name = req_dn
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
[ req_dn ]
O = Istio
CN = Root CA
EOF

openssl req -sha256 -new -key root-key.pem \
  -config root-ca.conf \
  -out root-cert.csr

openssl x509 -req -sha256 -days 3650 \
  -signkey root-key.pem \
  -extensions req_ext -extfile root-ca.conf \
  -in root-cert.csr \
  -out root-cert.pem

for cluster in west east; do
  mkdir $cluster

  openssl genrsa -out ${cluster}/ca-key.pem 4096
  cat <<EOF > ${cluster}/intermediate.conf
[ req ]
encrypt_key = no
prompt = no
utf8 = yes
default_md = sha256
default_bits = 4096
req_extensions = req_ext
x509_extensions = req_ext
distinguished_name = req_dn
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
subjectAltName=@san
[ san ]
DNS.1 = istiod.istio-system.svc
[ req_dn ]
O = Istio
CN = Intermediate CA
L = $cluster
EOF

  openssl req -new -config ${cluster}/intermediate.conf \
    -key ${cluster}/ca-key.pem \
    -out ${cluster}/cluster-ca.csr

  openssl x509 -req -sha256 -days 3650 \
    -CA root-cert.pem \
    -CAkey root-key.pem -CAcreateserial \
    -extensions req_ext -extfile ${cluster}/intermediate.conf \
    -in ${cluster}/cluster-ca.csr \
    -out ${cluster}/ca-cert.pem

  cat ${cluster}/ca-cert.pem root-cert.pem \
    > ${cluster}/cert-chain.pem
  cp root-cert.pem ${cluster}
done

kubectl --kubeconfig="${CLUSTER_A_KUBECONFIG}" create namespace istio-system
kubectl --kubeconfig="${CLUSTER_B_KUBECONFIG}" create namespace istio-system

kubectl --kubeconfig="${CLUSTER_A_KUBECONFIG}" label namespace istio-system topology.istio.io/network="${NETWORK_A}"
 kubectl create secret generic cacerts -n istio-system --kubeconfig="${CLUSTER_A_KUBECONFIG}" \
  --from-file=east/ca-cert.pem \
  --from-file=east/ca-key.pem \
  --from-file=east/root-cert.pem \
  --from-file=east/cert-chain.pem

kubectl --kubeconfig="${CLUSTER_B_KUBECONFIG}" label namespace istio-system topology.istio.io/network="${NETWORK_B}"
 kubectl create secret generic cacerts -n istio-system --kubeconfig="${CLUSTER_B_KUBECONFIG}" \
  --from-file=west/ca-cert.pem \
  --from-file=west/ca-key.pem \
  --from-file=west/root-cert.pem \
  --from-file=west/cert-chain.pem



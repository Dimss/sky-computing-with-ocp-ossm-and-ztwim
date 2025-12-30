source "$(dirname "$0")/01-define-exports.sh"

mkdir -p "${CERTS_DIR}"

openssl genpkey \
   -algorithm RSA \
   -out "${CERTS_DIR}/ca.key.pem"
   
openssl req -new -x509 -days 365 \
  -key "${CERTS_DIR}/ca.key.pem" \
  -out "${CERTS_DIR}/ca.crt.pem" \
  -subj "/CN=${CA_CN}"
  
openssl genpkey -algorithm RSA \
  -out "${CERTS_DIR}/${LEGACY_DB_SRV}.key.pem"
  
openssl req -new \
  -key "${CERTS_DIR}/${LEGACY_DB_SRV}.key.pem" \
  -out "${CERTS_DIR}/${LEGACY_DB_SRV}.csr.pem" \
  -subj "/CN=${CN_NODE_1}"

openssl x509 -req -days 365 \
 -in "${CERTS_DIR}/${LEGACY_DB_SRV}.csr.pem" \
 -CA "${CERTS_DIR}/ca.crt.pem" \
 -CAkey "${CERTS_DIR}/ca.key.pem" \
 -CAcreateserial -out "${CERTS_DIR}/${LEGACY_DB_SRV}.crt.pem" \
 -extfile <(printf "[v3_req]\nbasicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth,serverAuth") \
 -extensions v3_req
 

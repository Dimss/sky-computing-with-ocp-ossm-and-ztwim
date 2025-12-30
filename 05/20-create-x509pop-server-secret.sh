source "$(dirname "$0")/01-define-exports.sh"

export CA_CRT_PEM=$(sed 's/^/    /' < "$(dirname "$0")/data/ca.crt.pem" )

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: x509pop-ca
  namespace: "$ZTWIM_NS"
stringData:
  ca.crt.pem: |
${CA_CRT_PEM}
EOF

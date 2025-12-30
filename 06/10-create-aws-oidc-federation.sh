source "$(dirname "$0")/01-define-exports.sh"

export OIDC_ARN=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, '${ODIC_PROVIDER_URL}')].Arn" \
  --output text)

if [ -n "$OIDC_ARN" ]; then
  echo "OIDC Provider ARN: $OIDC_ARN"
else
  aws iam create-open-id-connect-provider \
      --url "https://${ODIC_PROVIDER_URL}" \
      --thumbprint-list "${FINGERPRINT}" \
      --client-id-list "${SPIFFE_AUDIENCE}"
fi




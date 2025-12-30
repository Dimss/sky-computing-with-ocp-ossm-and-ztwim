source "$(dirname "$0")/01-define-exports.sh"

export OIDC_ARN=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, '${ODIC_PROVIDER_URL}')].Arn" \
  --output text)

# Create the Trust Policy JSON file
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_ARN#*oidc-provider/}:aud": "$AUDIENCE"
        }
      }
    }
  ]
}
EOF

for policyArn in $(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" 2>/dev/null | jq -r .AttachedPolicies[].PolicyArn); do
  echo "detaching policy: ${policyArn}";
  aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${policyArn}" 2>/dev/null
done

aws iam delete-role \
  --role-name "${ROLE_NAME}" 2>/dev/null

aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/${AWS_BUILD_IN_POLICY}"







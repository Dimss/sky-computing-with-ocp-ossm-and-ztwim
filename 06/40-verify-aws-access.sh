source "$(dirname "$0")/01-define-exports.sh"
export ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" | jq -r .Role.Arn)
oc exec -it \
  "$(oc get \
      pods -o=jsonpath='{.items[0].metadata.name}' \
      -l app=aws-cli \
      -n "${TPJ}" \
   )" -n "${TPJ}" -- \
  aws dynamodb list-tables
source "$(dirname "$0")/01-define-exports.sh"

export ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" | jq -r .Role.Arn)
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-cli
  namespace: ${TPJ}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-config
  namespace: ${TPJ}
data:
  config: |
    [profile default]
    region = eu-north-1
    credential_process = curl -s http://localhost:9876/v1/creds
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-cli
  namespace: ${TPJ}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aws-cli
  template:
    metadata:
      annotations:
        inject.istio.io/templates: "sidecar,spire"
        spiffe.io/audience: "${SPIFFE_AUDIENCE}"
        spiffe.io/roleArn: "${ROLE_ARN}"
      labels:
        app: aws-cli
    spec:
      terminationGracePeriodSeconds: 0
      serviceAccountName: aws-cli
      containers:
      - name: aws-cli
        image: public.ecr.aws/aws-cli/aws-cli
        env:
        - name: AWS_CONFIG_FILE
          value: /tmp/aws/config
        command:
        - /bin/sh
        - -c
        - sleep inf
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: aws-config
          mountPath: "/tmp/aws"
          readOnly: true
      volumes:
      - name: aws-config
        configMap:
          name: aws-config
EOF

until oc get deployment aws-cli -n "${TPJ}" &> /dev/null; do sleep 3; done

oc wait --for=condition=Available deployment/aws-cli -n "${TPJ}" --timeout=300s

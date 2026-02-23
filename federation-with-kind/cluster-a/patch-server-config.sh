#!/bin/bash

# Get current config and validate JSON
CURRENT_CONFIG=$(kubectl get configmap spire-server -n spire-server -o jsonpath='{.data.server\.conf}')

# Validate current JSON
echo "Validating current JSON..."
if ! echo "$CURRENT_CONFIG" | jq . > /dev/null 2>&1; then
    echo "ERROR: Current server.conf is not valid JSON. Please fix the ConfigMap first."
    exit 1
fi

# Federation configuration
FEDERATION_CONFIG='{
"bundle_endpoint": {
    "address": "0.0.0.0",
    "port": 8443
  },
  "federates_with": {
    "cluster-b": {
      "bundle_endpoint_url": "https://spire-bundle.3tx7o.192.168.64.8.nip.io:9443",
      "bundle_endpoint_profile": {
        "https_spiffe": {
          "endpoint_spiffe_id": "spiffe://cluster-b/spire/server"
        }
      }
    }
  }
}'

# Merge federation config into server block
echo "Merging federation configuration..."
MERGED_CONFIG=$(echo "$CURRENT_CONFIG" | jq --argjson fed "$FEDERATION_CONFIG" '.server.federation = $fed')

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to merge federation configuration"
    exit 1
fi

# Show the merged config for review
echo "Merged configuration:"
echo "$MERGED_CONFIG" | jq .

# Apply the patch
echo "Applying configuration..."
kubectl patch configmap spire-server -n spire-server --type='merge' -p="{\"data\":{\"server.conf\":\"$(echo "$MERGED_CONFIG" | jq -c . | sed 's/"/\\"/g')\"}}"

if [ $? -eq 0 ]; then
    echo "Successfully patched spire-server ConfigMap!"
else
    echo "ERROR: Failed to patch ConfigMap"
    exit 1
fi

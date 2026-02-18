#!/bin/bash

# Configuration - REPLACE THESE VALUES WITH YOUR OWN
PROJECT_KEY="your-project-key"          # Example: "my-company" or "default"
FLAG_KEY="your-flag-key"                # Example: "promotional-banner" or "feature-toggle"
API_TOKEN="your-api-token"              # Get from: https://app.launchdarkly.com/settings/authorization

echo "🔴 Turning flag OFF..."
echo "📋 Flag: ${FLAG_KEY}"
echo "📋 Project: ${PROJECT_KEY}"
echo ""

# Turn flag OFF in production using semantic patch
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
  "https://app.launchdarkly.com/api/v2/flags/${PROJECT_KEY}/${FLAG_KEY}" \
  -H "Authorization: ${API_TOKEN}" \
  -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
  -d '{
    "comment": "Turning flag OFF via script",
    "environmentKey": "production",
    "instructions": [
      {
        "kind": "turnFlagOff"
      }
    ]
  }')

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "📊 Response:"
echo "HTTP Status: ${HTTP_CODE}"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    FLAG_STATUS=$(echo "$BODY" | jq -r '.environments.production.on')
    echo "✅ SUCCESS! Flag is now: ${FLAG_STATUS}"
    echo ""
    echo "🔗 View in UI: https://app.launchdarkly.com/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/production"
else
    echo "❌ ERROR: Failed to turn flag off"
    echo ""
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi


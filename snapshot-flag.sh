#!/bin/bash

# Configuration - REPLACE THESE VALUES WITH YOUR OWN
PROJECT_KEY="your-project-key"          # Example: "my-company" or "default"
FLAG_KEY="your-flag-key"                # Example: "promotional-banner" or "feature-toggle"
ENVIRONMENT="production"                # Example: "production", "staging", or "test"
API_TOKEN="your-api-token"              # Get from: https://app.launchdarkly.com/settings/authorization

# Output file with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="flag-snapshot-${TIMESTAMP}.json"

echo "📸 Taking snapshot of flag state..."
echo "📋 Flag: ${FLAG_KEY}"
echo "📋 Project: ${PROJECT_KEY}"
echo "📋 Environment: ${ENVIRONMENT}"
echo ""

# Fetch current flag configuration
echo "🔍 Fetching current flag configuration from LaunchDarkly API..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
  "https://app.launchdarkly.com/api/v2/flags/${PROJECT_KEY}/${FLAG_KEY}" \
  -H "Authorization: ${API_TOKEN}")

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo "📊 Response:"
echo "HTTP Status: ${HTTP_CODE}"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    # Save the full response
    echo "$BODY" | jq '.' > "$OUTPUT_FILE"

    echo "✅ SUCCESS! Flag snapshot saved to: ${OUTPUT_FILE}"
    echo ""

    # Extract key information for display (check the production environment)
    FLAG_ON=$(echo "$BODY" | jq -r ".environments.${ENVIRONMENT}.on")
    TARGETING=$(echo "$BODY" | jq -r "if .environments.${ENVIRONMENT}.on then \"Enabled\" else \"Disabled\" end")

    echo "📋 Current Flag State:"
    echo "   Flag ON/OFF: ${FLAG_ON}"
    echo "   Targeting: ${TARGETING}"
    echo ""

    echo "💾 This snapshot can be used to restore the flag to its current state."
    echo "🔗 View in UI: https://app.launchdarkly.com/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/${ENVIRONMENT}"
else
    echo "❌ ERROR: Failed to fetch flag configuration"
    echo ""
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi


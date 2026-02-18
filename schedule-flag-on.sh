#!/bin/bash

# Configuration - REPLACE THESE VALUES WITH YOUR OWN
PROJECT_KEY="your-project-key"          # Example: "my-company" or "default"
FLAG_KEY="your-flag-key"                # Example: "promotional-banner" or "feature-toggle"
ENVIRONMENT="production"                # Example: "production", "staging", or "test"
API_TOKEN="your-api-token"              # Get from: https://app.launchdarkly.com/settings/authorization

# Calculate timestamp (customize the time delay as needed)
MINUTES_FROM_NOW=5  # Change this to your desired delay
NOW=$(date +%s)
TURN_ON_TIME=$((($NOW + ($MINUTES_FROM_NOW * 60)) * 1000))   # Convert to milliseconds

echo "🚀 Scheduling flag to turn ON..."
echo "📅 Flag: ${FLAG_KEY}"
echo "📅 Project: ${PROJECT_KEY}"
echo "📅 Environment: ${ENVIRONMENT}"
echo "📅 Scheduled time: $(date -r $(($TURN_ON_TIME/1000)) '+%Y-%m-%d %H:%M:%S')"
echo ""

# Schedule flag to turn ON
echo "⏰ Making API call to schedule the flag..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://app.launchdarkly.com/api/v2/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/environments/${ENVIRONMENT}/scheduled-changes" \
  -H "Authorization: ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"comment\": \"Scheduled to turn ON flag in ${MINUTES_FROM_NOW} minutes\",
    \"executionDate\": ${TURN_ON_TIME},
    \"instructions\": [
      {
        \"kind\": \"turnFlagOn\"
      }
    ]
  }")

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo "📊 Response:"
echo "HTTP Status: ${HTTP_CODE}"
echo ""

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS! Scheduled change created."
    echo ""
    echo "$BODY" | jq '.'
    echo ""
    SCHEDULE_ID=$(echo "$BODY" | jq -r '._id')
    echo "🆔 Scheduled Change ID: ${SCHEDULE_ID}"
    echo "⚠️  IMPORTANT: Save this ID - you'll need it to verify or cancel if needed"
    echo "🔗 View in UI: https://app.launchdarkly.com/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/${ENVIRONMENT}"
else
    echo "❌ ERROR: Failed to create scheduled change"
    echo ""
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi


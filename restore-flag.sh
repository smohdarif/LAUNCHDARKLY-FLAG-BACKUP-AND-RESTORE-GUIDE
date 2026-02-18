#!/bin/bash

# Configuration - REPLACE THESE VALUES WITH YOUR OWN
PROJECT_KEY="your-project-key"          # Example: "my-company" or "default"
FLAG_KEY="your-flag-key"                # Example: "promotional-banner" or "feature-toggle"
ENVIRONMENT="production"                # Example: "production", "staging", or "test"
API_TOKEN="your-api-token"              # Get from: https://app.launchdarkly.com/settings/authorization

# Check if snapshot file is provided
if [ -z "$1" ]; then
    echo "❌ ERROR: Please provide a snapshot file as an argument"
    echo ""
    echo "Usage: $0 <snapshot-file.json> <minutes-from-now>"
    echo ""
    echo "Examples:"
    echo "  $0 flag-snapshot-20260218-120000.json 60     # Restore in 60 minutes"
    echo "  $0 flag-snapshot-20260218-120000.json 120    # Restore in 2 hours"
    echo ""
    echo "Available snapshots:"
    ls -1 flag-snapshot-*.json 2>/dev/null || echo "  (none found)"
    exit 1
fi

SNAPSHOT_FILE="$1"
SCHEDULE_MINUTES="${2:-60}"  # Default to 60 minutes if not provided

# Check if snapshot file exists
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "❌ ERROR: Snapshot file not found: ${SNAPSHOT_FILE}"
    exit 1
fi

echo "🔄 Scheduling flag restore from snapshot..."
echo "📋 Flag: ${FLAG_KEY}"
echo "📋 Project: ${PROJECT_KEY}"
echo "📋 Environment: ${ENVIRONMENT}"
echo "📄 Snapshot: ${SNAPSHOT_FILE}"
echo ""

# Extract the flag state from snapshot (from the specified environment)
FLAG_ON=$(jq -r ".environments.${ENVIRONMENT}.on" "$SNAPSHOT_FILE")

if [ "$FLAG_ON" = "null" ] || [ -z "$FLAG_ON" ]; then
    echo "❌ ERROR: Invalid snapshot file - cannot read flag state for environment: ${ENVIRONMENT}"
    exit 1
fi

echo "📊 Snapshot shows flag state:"
echo "   Flag ON/OFF: ${FLAG_ON}"
echo ""

# Determine the instruction based on flag state
if [ "$FLAG_ON" = "true" ]; then
    INSTRUCTION='{"kind": "turnFlagOn"}'
    ACTION="turn ON"
else
    INSTRUCTION='{"kind": "turnFlagOff"}'
    ACTION="turn OFF"
fi

# Calculate timestamp for scheduled execution
NOW=$(date +%s)
EXECUTION_TIME=$((($NOW + ($SCHEDULE_MINUTES * 60)) * 1000))

echo "⏰ Scheduling flag to ${ACTION} in ${SCHEDULE_MINUTES} minutes..."
echo "📅 Scheduled time: $(date -r $(($EXECUTION_TIME/1000)) '+%Y-%m-%d %H:%M:%S')"
echo ""

# Schedule the change
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://app.launchdarkly.com/api/v2/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/environments/${ENVIRONMENT}/scheduled-changes" \
  -H "Authorization: ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"comment\": \"Restore flag to state from snapshot: ${SNAPSHOT_FILE}\",
    \"executionDate\": ${EXECUTION_TIME},
    \"instructions\": [${INSTRUCTION}]
  }")

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "📊 Response:"
echo "HTTP Status: ${HTTP_CODE}"
echo ""

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS! Restore scheduled."
    echo ""
    echo "$BODY" | jq '.'
    echo ""
    SCHEDULE_ID=$(echo "$BODY" | jq -r '._id')
    echo "🆔 Scheduled Change ID: ${SCHEDULE_ID}"
    echo "⚠️  IMPORTANT: Save this ID - you'll need it to verify or cancel if needed"
    echo "🔗 View in UI: https://app.launchdarkly.com/projects/${PROJECT_KEY}/flags/${FLAG_KEY}/${ENVIRONMENT}"
else
    echo "❌ ERROR: Failed to schedule restore"
    echo ""
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi


#!/bin/bash

# Configuration - REPLACE THESE VALUES WITH YOUR OWN
PROJECT_KEY="your-project-key"          # Example: "my-company" or "default"
FLAG_KEY="your-flag-key"                # Example: "promotional-banner" or "feature-toggle"
ENVIRONMENT="production"                # Example: "production", "staging", or "test"
API_TOKEN="your-api-token"              # Get from: https://app.launchdarkly.com/settings/authorization

# Function to convert time with unit to minutes
convert_to_minutes() {
    local time_value="$1"

    # If no unit specified, assume minutes
    if [[ "$time_value" =~ ^[0-9]+$ ]]; then
        echo "$time_value"
        return
    fi

    # Extract number and unit
    local number="${time_value//[^0-9]/}"
    local unit="${time_value//[0-9]/}"

    case "$unit" in
        m|min|mins|minute|minutes)
            echo "$number"
            ;;
        h|hr|hrs|hour|hours)
            echo "$((number * 60))"
            ;;
        d|day|days)
            echo "$((number * 1440))"
            ;;
        *)
            echo "ERROR: Invalid unit '$unit'. Use m/h/d (minutes/hours/days)" >&2
            return 1
            ;;
    esac
}

# Check if snapshot file is provided
if [ -z "$1" ]; then
    echo "❌ ERROR: Please provide a snapshot file as an argument"
    echo ""
    echo "Usage: $0 <snapshot-file.json> <time>"
    echo ""
    echo "Time formats supported:"
    echo "  - Minutes: 60, 60m, 60min, 60minutes"
    echo "  - Hours:   2h, 2hr, 2hours"
    echo "  - Days:    3d, 3day, 3days"
    echo ""
    echo "Examples:"
    echo "  $0 flag-snapshot-20260218-120000.json 30m       # Restore in 30 minutes"
    echo "  $0 flag-snapshot-20260218-120000.json 2h        # Restore in 2 hours"
    echo "  $0 flag-snapshot-20260218-120000.json 3d        # Restore in 3 days"
    echo "  $0 flag-snapshot-20260218-120000.json 60        # Restore in 60 minutes (no unit = minutes)"
    echo ""
    echo "Available snapshots:"
    ls -1 flag-snapshot-*.json 2>/dev/null || echo "  (none found)"
    exit 1
fi

SNAPSHOT_FILE="$1"
SCHEDULE_TIME="${2:-60m}"  # Default to 60 minutes if not provided

# Convert time to minutes
SCHEDULE_MINUTES=$(convert_to_minutes "$SCHEDULE_TIME")
if [ $? -ne 0 ]; then
    echo "❌ $SCHEDULE_MINUTES"
    exit 1
fi

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

# Calculate friendly time display
HOURS=$((SCHEDULE_MINUTES / 60))
DAYS=$((SCHEDULE_MINUTES / 1440))
REMAINING_HOURS=$(((SCHEDULE_MINUTES % 1440) / 60))
REMAINING_MINUTES=$((SCHEDULE_MINUTES % 60))

if [ $SCHEDULE_MINUTES -ge 1440 ]; then
    if [ $REMAINING_HOURS -eq 0 ]; then
        TIME_DISPLAY="${DAYS} day(s)"
    else
        TIME_DISPLAY="${DAYS} day(s) ${REMAINING_HOURS} hour(s)"
    fi
elif [ $SCHEDULE_MINUTES -ge 60 ]; then
    if [ $REMAINING_MINUTES -eq 0 ]; then
        TIME_DISPLAY="${HOURS} hour(s)"
    else
        TIME_DISPLAY="${HOURS} hour(s) ${REMAINING_MINUTES} minute(s)"
    fi
else
    TIME_DISPLAY="${SCHEDULE_MINUTES} minute(s)"
fi

echo "⏰ Scheduling flag to ${ACTION}..."
echo "⏱️  Time from now: ${TIME_DISPLAY}"
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


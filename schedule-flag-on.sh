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

# Calculate timestamp (customize the time delay as needed)
# Supported formats: 5m, 2h, 3d, or just 5 (assumes minutes)
SCHEDULE_TIME="${1:-5m}"  # Default to 5 minutes if not provided

# Convert time to minutes
MINUTES_FROM_NOW=$(convert_to_minutes "$SCHEDULE_TIME")
if [ $? -ne 0 ]; then
    echo "❌ $MINUTES_FROM_NOW"
    echo ""
    echo "Usage: $0 <time>"
    echo ""
    echo "Time formats supported:"
    echo "  - Minutes: 5, 5m, 5min, 5minutes"
    echo "  - Hours:   2h, 2hr, 2hours"
    echo "  - Days:    3d, 3day, 3days"
    echo ""
    echo "Examples:"
    echo "  $0 5m    # Schedule in 5 minutes"
    echo "  $0 2h    # Schedule in 2 hours"
    echo "  $0 3d    # Schedule in 3 days"
    echo "  $0 30    # Schedule in 30 minutes (no unit = minutes)"
    exit 1
fi

NOW=$(date +%s)
TURN_ON_TIME=$((($NOW + ($MINUTES_FROM_NOW * 60)) * 1000))   # Convert to milliseconds

# Calculate friendly time display
HOURS=$((MINUTES_FROM_NOW / 60))
DAYS=$((MINUTES_FROM_NOW / 1440))
REMAINING_HOURS=$(((MINUTES_FROM_NOW % 1440) / 60))
REMAINING_MINUTES=$((MINUTES_FROM_NOW % 60))

if [ $MINUTES_FROM_NOW -ge 1440 ]; then
    if [ $REMAINING_HOURS -eq 0 ]; then
        TIME_DISPLAY="${DAYS} day(s)"
    else
        TIME_DISPLAY="${DAYS} day(s) ${REMAINING_HOURS} hour(s)"
    fi
elif [ $MINUTES_FROM_NOW -ge 60 ]; then
    if [ $REMAINING_MINUTES -eq 0 ]; then
        TIME_DISPLAY="${HOURS} hour(s)"
    else
        TIME_DISPLAY="${HOURS} hour(s) ${REMAINING_MINUTES} minute(s)"
    fi
else
    TIME_DISPLAY="${MINUTES_FROM_NOW} minute(s)"
fi

echo "🚀 Scheduling flag to turn ON..."
echo "📅 Flag: ${FLAG_KEY}"
echo "📅 Project: ${PROJECT_KEY}"
echo "📅 Environment: ${ENVIRONMENT}"
echo "⏱️  Time from now: ${TIME_DISPLAY}"
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


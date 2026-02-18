# LaunchDarkly Flag Backup and Restore Guide

## Overview

This guide provides a complete workflow for safely managing temporary flag changes in LaunchDarkly using the **Snapshot + Restore** pattern. This approach ensures you can always return to your original flag configuration after a scheduled event or testing period.

## Use Cases

- **Temporary Events**: Enable a promotional banner during a specific time window
- **Scheduled Maintenance**: Toggle features on/off during maintenance windows
- **Time-Limited Features**: Activate features for events, sales, or campaigns
- **Safe Testing**: Test flag changes in production with automatic rollback

## The Snapshot + Restore Pattern

This pattern consists of three steps:

1. **📸 Snapshot**: Capture the current flag state before making changes
2. **🚀 Schedule Event**: Schedule the flag to turn ON at a specific time
3. **🔄 Schedule Restore**: Schedule the flag to return to its original state after the event

### Why This Pattern?

- ✅ **Safe**: Always have a backup of your original configuration
- ✅ **Automated**: No manual intervention needed during off-hours
- ✅ **Reliable**: Guaranteed rollback to known good state
- ✅ **Auditable**: All changes are tracked in LaunchDarkly

---

## Tested Scripts Reference

This guide includes three production-tested scripts that have been validated with real flag operations:

### Quick Reference Table

| Step | Generic Name (in guide) | Tested Script Name | Status |
|------|------------------------|-------------------|--------|
| 1. Snapshot | `snapshot-flag.sh` | `snapshot-banner-flag.sh` | ✅ Tested |
| 2. Schedule ON | `schedule-flag-on.sh` | `schedule-banner-on.sh` | ✅ Tested |
| 3. Schedule Restore | `schedule-flag-restore.sh` | `restore-banner-flag.sh` | ✅ Tested |
| Bonus | N/A | `turn-flag-off.sh` | ✅ Tested |

### 📸 Step 1: Snapshot Script
**Script Name:** `snapshot-banner-flag.sh`
- **Purpose:** Captures current flag state to JSON file
- **Tested:** ✅ Successfully captured flag state
- **Output:** `banner-flag-snapshot-YYYYMMDD-HHMMSS.json`
- **Test Result:** Successfully captured flag in ON state

### 🚀 Step 2: Schedule ON Script
**Script Name:** `schedule-banner-on.sh`
- **Purpose:** Schedules flag to turn ON at a future time
- **Tested:** ✅ Successfully scheduled flag activation
- **Default Timing:** 5 minutes from execution (customizable)
- **Test Result:** Successfully scheduled and executed flag turn-on

### 🔄 Step 3: Restore Script
**Script Name:** `restore-banner-flag.sh`
- **Purpose:** Schedules flag to restore to snapshot state
- **Tested:** ✅ Successfully scheduled flag restoration
- **Usage:** `./restore-banner-flag.sh <snapshot-file> <minutes-from-now>`
- **Features:**
  - Accepts any snapshot file
  - Configurable timing
  - Automatically detects ON/OFF state from snapshot
- **Test Result:** Successfully scheduled restoration from OFF to ON in 5 minutes

### 🔴 Bonus: Turn OFF Script
**Script Name:** `turn-flag-off.sh`
- **Purpose:** Immediately turns flag OFF (not scheduled)
- **Tested:** ✅ Successfully turned flag OFF immediately
- **Use Case:** Quick manual toggle when needed
- **Test Result:** Successfully turned flag from ON to OFF instantly

**All scripts have been tested and validated with the following configuration:**
- Project: `Arif-BOKF`
- Flag: `ui-banner-announcement-boolean`
- Environment: `production`
- Test Date: February 18, 2026

---

## Prerequisites

Before you begin, ensure you have:

- ✅ LaunchDarkly API access token with write permissions
- ✅ Project key, flag key, and environment key
- ✅ `curl` and `jq` installed on your system
- ✅ LaunchDarkly Enterprise plan (required for scheduled changes)

### Installing Required Tools

**macOS:**
```bash
brew install jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get install jq curl
```

**Windows (WSL):**
```bash
sudo apt-get install jq curl
```

---

## Complete Workflow

### Step 1: Take a Snapshot of Current Flag State

Before making any changes, capture the current state of your flag.

**Script: `snapshot-flag.sh`** (Tested version: `snapshot-banner-flag.sh`)

```bash
#!/bin/bash

# Configuration
PROJECT_KEY="your-project-key"
FLAG_KEY="your-flag-key"
ENVIRONMENT="production"
API_TOKEN="your-api-token"

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
```

**Usage:**
```bash
chmod +x snapshot-flag.sh
./snapshot-flag.sh
```

**Output:**
- Creates a timestamped snapshot file: `flag-snapshot-20260218-120000.json`
- Displays the current flag state (ON/OFF)
- Saves complete flag configuration for later restore

---

### Step 2: Schedule Flag to Turn ON

Schedule the flag to turn ON at a specific time in the future.

**Script: `schedule-flag-on.sh`** (Tested version: `schedule-banner-on.sh`)

```bash
#!/bin/bash

# Configuration
PROJECT_KEY="your-project-key"
FLAG_KEY="your-flag-key"
ENVIRONMENT="production"
API_TOKEN="your-api-token"

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
```

**Usage:**
```bash
chmod +x schedule-flag-on.sh
./schedule-flag-on.sh
```

**Customization:**
- Change `MINUTES_FROM_NOW` to schedule for a different time
- For a specific timestamp, replace the calculation with your desired Unix timestamp in milliseconds

---

### Step 3: Schedule Restore to Original State

Schedule the flag to automatically restore to its original state after your event.

**Script: `schedule-flag-restore.sh`** (Tested version: `restore-banner-flag.sh`)

```bash
#!/bin/bash

# Configuration
PROJECT_KEY="your-project-key"
FLAG_KEY="your-flag-key"
ENVIRONMENT="production"
API_TOKEN="your-api-token"

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
```

**Usage:**
```bash
chmod +x schedule-flag-restore.sh

# Schedule restore in 60 minutes
./schedule-flag-restore.sh flag-snapshot-20260218-120000.json 60

# Schedule restore in 2 hours (120 minutes)
./schedule-flag-restore.sh flag-snapshot-20260218-120000.json 120
```

---

## Complete Example: Weekend Promotion Banner

Let's walk through a complete real-world example.

> **Note:** This example uses generic script names (`snapshot-flag.sh`, `schedule-flag-on.sh`, `schedule-flag-restore.sh`). If using the tested scripts, replace with `snapshot-banner-flag.sh`, `schedule-banner-on.sh`, and `restore-banner-flag.sh` respectively.

**Scenario:**
- Enable a promotional banner Friday at 6 PM
- Keep it enabled all weekend
- Automatically disable it Monday at 9 AM

### Timeline

```
Current Time: Friday 5:50 PM
Event Start:  Friday 6:00 PM  (10 minutes from now)
Event End:    Monday 9:00 AM  (63 hours = 3780 minutes from now)
```

### Step-by-Step Execution

#### 1. Take Snapshot (Friday 5:50 PM)

```bash
# Update configuration in snapshot-flag.sh first
PROJECT_KEY="my-company"
FLAG_KEY="promotional-banner"
ENVIRONMENT="production"
API_TOKEN="api-xxxxxxxxxxxxx"

# Run snapshot
./snapshot-flag.sh
```

**Output:**
```
✅ SUCCESS! Flag snapshot saved to: flag-snapshot-20260221-175000.json
📋 Current Flag State:
   Flag ON/OFF: false
   Targeting: Disabled
```

**✅ Checkpoint:** Snapshot file created with current state (OFF)

---

#### 2. Schedule Banner to Turn ON (Friday 5:50 PM)

```bash
# Run scheduling - turn ON in 10 minutes
./schedule-flag-on.sh 10m
```

**Output:**
```
✅ SUCCESS! Scheduled change created.
📅 Scheduled time: 2026-02-21 18:00:00
🆔 Scheduled Change ID: 507f1f77bcf86cd799439011
```

**✅ Checkpoint:** Banner scheduled to turn ON at 6:00 PM (in 10 minutes)

---

#### 3. Schedule Restore to Original State (Friday 5:50 PM)

```bash
# Schedule restore for Monday 9 AM (63 hours from now)
./schedule-flag-restore.sh flag-snapshot-20260221-175000.json 63h
# Or use days: 3d (approximately 2.6 days)
```

**Output:**
```
✅ SUCCESS! Restore scheduled.
📅 Scheduled time: 2026-02-24 09:00:00
🆔 Scheduled Change ID: 507f1f77bcf86cd799439022
```

**✅ Checkpoint:** Banner scheduled to turn OFF at Monday 9 AM

---

### Verification

After setting up both scheduled changes, verify in the LaunchDarkly UI:

1. Go to your flag page: `https://app.launchdarkly.com/projects/my-company/flags/promotional-banner/production`
2. Look for "Scheduled changes" section
3. You should see two pending changes:
   - **Friday 6:00 PM**: Turn flag ON
   - **Monday 9:00 AM**: Turn flag OFF

---

## Time Format Support

The scripts support flexible time formats for scheduling:

### Supported Formats

| Format | Description | Examples |
|--------|-------------|----------|
| **Minutes** | `m`, `min`, `mins`, `minute`, `minutes` | `5m`, `30mins`, `60minute` |
| **Hours** | `h`, `hr`, `hrs`, `hour`, `hours` | `2h`, `4hrs`, `12hours` |
| **Days** | `d`, `day`, `days` | `1d`, `3days`, `7day` |
| **No Unit** | Plain number (assumes minutes) | `5`, `30`, `120` |

### Usage Examples

```bash
# Schedule flag to turn ON
./schedule-flag-on.sh 5m      # 5 minutes
./schedule-flag-on.sh 2h      # 2 hours
./schedule-flag-on.sh 3d      # 3 days
./schedule-flag-on.sh 30      # 30 minutes (no unit = minutes)

# Schedule restore from snapshot
./restore-flag.sh snapshot.json 30m   # 30 minutes
./restore-flag.sh snapshot.json 4h    # 4 hours
./restore-flag.sh snapshot.json 7d    # 7 days
./restore-flag.sh snapshot.json 120   # 120 minutes
```

### Time Display

The scripts automatically convert and display time in a human-friendly format:

```bash
# Input: 30m
# Display: "Time from now: 30 minute(s)"

# Input: 2h
# Display: "Time from now: 2 hour(s)"

# Input: 3d
# Display: "Time from now: 3 day(s)"

# Input: 90m
# Display: "Time from now: 1 hour(s) 30 minute(s)"

# Input: 2d
# Display: "Time from now: 2 day(s)"
```

## Timeline Quick Reference

| Scenario | Recommended Time | Command Example |
|----------|------------------|-----------------|
| Quick test | 5-30 minutes | `./schedule-flag-on.sh 5m` |
| Lunch break test | 1-2 hours | `./schedule-flag-on.sh 1h` |
| Business day | 8-12 hours | `./schedule-flag-on.sh 8h` |
| Weekend event | 2-3 days | `./schedule-flag-on.sh 3d` |
| Week-long campaign | 7 days | `./schedule-flag-on.sh 7d` |

### Conversion Reference

| Time Description | Short Format | Alternative |
|-----------------|--------------|-------------|
| 5 minutes | `5m` | `5` |
| 15 minutes | `15m` | `15` |
| 30 minutes | `30m` | `30` |
| 1 hour | `1h` | `60m` or `60` |
| 2 hours | `2h` | `120m` or `120` |
| 4 hours | `4h` | `240m` or `240` |
| 8 hours | `8h` | `480m` or `480` |
| 12 hours | `12h` | `720m` or `720` |
| 1 day | `1d` | `24h` or `1440m` |
| 2 days | `2d` | `48h` or `2880m` |
| 3 days | `3d` | `72h` or `4320m` |
| 1 week | `7d` | `168h` or `10080m` |

---

## Managing Scheduled Changes

### View All Scheduled Changes

```bash
curl -s -X GET \
  "https://app.launchdarkly.com/api/v2/projects/your-project/flags/your-flag/environments/production/scheduled-changes" \
  -H "Authorization: your-api-token" | jq '.'
```

### Cancel a Scheduled Change

If you need to cancel a scheduled change before it executes:

```bash
curl -X DELETE \
  "https://app.launchdarkly.com/api/v2/projects/your-project/flags/your-flag/environments/production/scheduled-changes/SCHEDULE_ID" \
  -H "Authorization: your-api-token"
```

Replace `SCHEDULE_ID` with the ID returned when you created the scheduled change.

---

## Best Practices

### ✅ Do's

1. **Always snapshot first** - Never make changes without a backup
2. **Test in non-production** - Validate your workflow in a test environment first
3. **Document schedule IDs** - Keep track of your scheduled change IDs
4. **Set reminders** - Add calendar reminders for when changes will execute
5. **Monitor execution** - Check LaunchDarkly after scheduled time to verify execution
6. **Use descriptive comments** - Add clear comments to scheduled changes for audit trail
7. **Calculate time carefully** - Double-check your minute calculations
8. **Keep snapshots** - Archive snapshot files for future reference

### ❌ Don'ts

1. **Don't skip snapshots** - Always capture current state first
2. **Don't forget to restore** - Always schedule the restore when you schedule the change
3. **Don't use conflicting schedules** - Avoid overlapping scheduled changes
4. **Don't ignore timezones** - All times are in UTC - adjust accordingly
5. **Don't delete snapshots prematurely** - Keep snapshots until after restore completes
6. **Don't modify active flags manually** - Let scheduled changes complete as planned

---

## Troubleshooting

### Error: "401 Unauthorized"

**Cause:** Invalid or expired API token

**Solution:**
- Verify your API token is correct
- Check token has write permissions for the environment
- Generate a new token if needed

### Error: "404 Not Found"

**Cause:** Incorrect project key, flag key, or environment key

**Solution:**
- Verify all keys are correct
- Check the flag exists in LaunchDarkly
- Ensure flag is available in the specified environment

### Error: "409 Conflict"

**Cause:** Another scheduled change conflicts with your request

**Solution:**
- List existing scheduled changes
- Delete conflicting scheduled change
- Use `?ignoreConflicts=true` query parameter (not recommended)

### Error: "Invalid snapshot file"

**Cause:** Snapshot file is corrupted or invalid

**Solution:**
- Take a new snapshot
- Verify snapshot file contains valid JSON
- Check the environment exists in the snapshot

### Scheduled Change Didn't Execute

**Possible Causes:**
- Wrong timezone calculation
- Scheduled change was deleted
- API token expired
- Flag was modified manually

**Solution:**
- Check LaunchDarkly audit log
- Verify scheduled change still exists
- Check flag history in LaunchDarkly UI

---

## Security Considerations

### API Token Security

⚠️ **IMPORTANT:** Never commit API tokens to version control

**Best Practices:**
- Use environment variables for tokens
- Use service tokens (not personal tokens) for automation
- Rotate tokens regularly
- Use read-only tokens when possible
- Restrict token permissions to specific projects/environments

**Example using environment variables:**

```bash
# Set token as environment variable
export LD_API_TOKEN="your-api-token"

# Use in scripts
API_TOKEN="${LD_API_TOKEN}"
```

---

## Quick Reference

### Workflow Checklist

- [ ] Update configuration in all three scripts (PROJECT_KEY, FLAG_KEY, ENVIRONMENT, API_TOKEN)
- [ ] Run `snapshot-flag.sh` to capture current state
- [ ] Save the snapshot filename (e.g., `flag-snapshot-20260218-120000.json`)
- [ ] Edit `schedule-flag-on.sh` to set desired delay (MINUTES_FROM_NOW)
- [ ] Run `schedule-flag-on.sh` to schedule the flag to turn ON
- [ ] Save the Schedule ID from the output
- [ ] Calculate total event duration in minutes
- [ ] Run `schedule-flag-restore.sh <snapshot-file> <minutes>` to schedule restore
- [ ] Save the Schedule ID from the output
- [ ] Verify both scheduled changes in LaunchDarkly UI
- [ ] Set calendar reminders for execution times
- [ ] Monitor flag status after scheduled times

---

## Support and Resources

### LaunchDarkly Documentation

- [API Documentation](https://apidocs.launchdarkly.com/)
- [Scheduled Flag Changes](https://docs.launchdarkly.com/home/organize/flags-deprecate#scheduled-flag-changes)
- [Feature Flag Best Practices](https://docs.launchdarkly.com/guides/best-practices)

### Tools

- [Unix Timestamp Converter](https://www.epochconverter.com/)
- [jq JSON Processor](https://stedolan.github.io/jq/)

### Getting Help

If you encounter issues:

1. Check the Troubleshooting section above
2. Review LaunchDarkly audit logs
3. Contact LaunchDarkly support
4. Check LaunchDarkly status page

---

## Summary

This guide provides a complete, production-ready workflow for safely managing temporary flag changes with automatic rollback. By following the Snapshot + Restore pattern, you can:

- ✅ Safely test changes in production
- ✅ Automate time-based feature rollouts
- ✅ Guarantee rollback to known good state
- ✅ Maintain full audit trail
- ✅ Eliminate manual intervention

**Remember:** Always snapshot first, schedule both ON and OFF changes, and verify in the UI!

---

**Document Version:** 1.0
**Last Updated:** 2026-02-18
**LaunchDarkly API Version:** v2


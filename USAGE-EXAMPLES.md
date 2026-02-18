# Usage Examples

This document provides real-world examples of using the LaunchDarkly Flag Backup and Restore scripts.

## Example 1: Boolean Flag - Quick Test

### Scenario
Test a boolean feature flag by turning it ON for 30 minutes, then automatically restore to original state.

### Steps

```bash
# Step 1: Take snapshot
./snapshot-flag.sh
# Output: flag-snapshot-20260218-140000.json

# Step 2: Schedule to turn ON in 2 minutes
./schedule-flag-on.sh 2m

# Step 3: Schedule restore in 30 minutes
./restore-flag.sh flag-snapshot-20260218-140000.json 30m
```

### Result
- Flag turns ON in 2 minutes
- Flag automatically restores to original state after 30 minutes
- Zero manual intervention needed

---

## Example 2: String Flag - Full Workflow

### Scenario
Managing a banner announcement (string flag) with different message variations.

### Configuration
```bash
PROJECT_KEY="your-project"
FLAG_KEY="banner-message"
ENVIRONMENT="production"
```

### Steps

```bash
# Step 1: Take snapshot of current banner state
./snapshot-flag.sh
# Shows: Current banner is ON, serving "Welcome message"
# Output: flag-snapshot-20260218-150000.json

# Step 2: Turn banner OFF (hide it)
./turn-flag-off.sh

# Step 3: Schedule banner to turn back ON in 5 minutes
./restore-flag.sh flag-snapshot-20260218-150000.json 5m
```

### Result
- Banner turned OFF immediately
- Banner automatically turns back ON in 5 minutes
- Returns to exact previous state ("Welcome message")

---

## Example 3: Weekend Promotion

### Scenario
Enable a promotional banner Friday evening, keep it on all weekend, turn off Monday morning.

### Timeline
- Friday 6:00 PM - Banner goes ON
- Monday 9:00 AM - Banner goes OFF (back to original state)
- Duration: 63 hours (2.625 days)

### Steps

```bash
# Friday 5:50 PM - Take snapshot
./snapshot-flag.sh
# Output: flag-snapshot-20260221-175000.json

# Schedule banner to turn ON in 10 minutes (6:00 PM)
./schedule-flag-on.sh 10m

# Schedule restore for Monday 9 AM (63 hours from now)
./restore-flag.sh flag-snapshot-20260221-175000.json 63h
# Or use: ./restore-flag.sh flag-snapshot-20260221-175000.json 3d
```

### Result
- ✅ Friday 6:00 PM: Banner turns ON automatically
- ✅ Weekend: Banner stays ON
- ✅ Monday 9:00 AM: Banner turns OFF automatically
- ✅ Zero weekend work required!

---

## Example 4: Multi-Flag Management

### Scenario
Managing multiple flags for a coordinated feature launch.

### Flags
1. `feature-enabled` (boolean)
2. `feature-message` (string)
3. `feature-settings` (JSON)

### Steps for Each Flag

```bash
# Feature 1: Main feature toggle
PROJECT_KEY="myapp"
FLAG_KEY="feature-enabled"
./snapshot-flag.sh
# Output: flag-snapshot-feature-enabled-20260218-160000.json

# Feature 2: Message banner
FLAG_KEY="feature-message"
./snapshot-flag.sh
# Output: flag-snapshot-feature-message-20260218-160000.json

# Feature 3: Settings
FLAG_KEY="feature-settings"
./snapshot-flag.sh
# Output: flag-snapshot-feature-settings-20260218-160000.json

# Schedule all to turn ON in 30 minutes
./schedule-flag-on.sh 30m  # Repeat for each flag (update FLAG_KEY)

# Schedule all to restore in 24 hours
./restore-flag.sh flag-snapshot-feature-enabled-20260218-160000.json 24h
./restore-flag.sh flag-snapshot-feature-message-20260218-160000.json 24h
./restore-flag.sh flag-snapshot-feature-settings-20260218-160000.json 24h
```

---

## Example 5: Emergency Rollback Test

### Scenario
Test your ability to quickly rollback a feature in production.

### Steps

```bash
# Step 1: Snapshot current production state
./snapshot-flag.sh
# Output: flag-snapshot-20260218-170000.json

# Step 2: Turn feature OFF immediately (simulate rollback)
./turn-flag-off.sh

# Step 3: Verify feature is OFF in production
# Check your application - feature should be disabled

# Step 4: Restore when ready (e.g., 10 minutes)
./restore-flag.sh flag-snapshot-20260218-170000.json 10m
```

### Result
- Tested emergency rollback procedure
- Confirmed rollback works
- Automatically restored after 10 minutes
- Validated incident response process

---

## Example 6: Business Hours Only Feature

### Scenario
Enable a feature during business hours only (9 AM - 5 PM).

### Monday Morning Setup

```bash
# 8:50 AM - Take snapshot (feature is OFF)
./snapshot-flag.sh
# Output: flag-snapshot-monday-085000.json

# Schedule to turn ON at 9 AM (10 minutes from now)
./schedule-flag-on.sh 10m

# Schedule to turn OFF at 5 PM (8 hours from now)
./restore-flag.sh flag-snapshot-monday-085000.json 8h
```

### Result
- 9:00 AM: Feature turns ON
- 5:00 PM: Feature turns OFF
- Repeat daily as needed

---

## Example 7: A/B Test with Time Limit

### Scenario
Run an A/B test for exactly 48 hours, then revert.

### Steps

```bash
# Day 1 - Start A/B test
./snapshot-flag.sh
# Output: flag-snapshot-20260218-100000.json
# Current: Control group (variation 0)

# Manually change to test group (variation 1) in LaunchDarkly UI
# Or use API to update flag

# Schedule restore to control group in 48 hours
./restore-flag.sh flag-snapshot-20260218-100000.json 48h
# Or use: ./restore-flag.sh flag-snapshot-20260218-100000.json 2d
```

### Result
- A/B test runs for exactly 48 hours
- Automatically reverts to control group
- No need to remember to turn it off

---

## Example 8: Maintenance Window

### Scenario
Disable feature during maintenance, restore after maintenance completes.

### Planned Maintenance: 2 AM - 4 AM

```bash
# 1:50 AM - Take snapshot (feature is ON)
./snapshot-flag.sh
# Output: flag-snapshot-20260219-015000.json

# Schedule to turn OFF at 2 AM (10 minutes from now)
./schedule-flag-on.sh 10m  # Wait, we want OFF, not ON!
# Use turn-flag-off.sh or create a schedule-flag-off.sh

# Better approach: Turn OFF now, schedule restore for 4 AM
./turn-flag-off.sh

# Schedule restore for 4 AM (2 hours 10 minutes from now)
./restore-flag.sh flag-snapshot-20260219-015000.json 130m
```

### Result
- Feature disabled during maintenance
- Feature automatically restored at 4 AM
- Users see feature return seamlessly

---

## Time Format Quick Reference

All scripts support flexible time formats:

```bash
# Minutes
./schedule-flag-on.sh 5m
./schedule-flag-on.sh 30mins

# Hours
./schedule-flag-on.sh 2h
./schedule-flag-on.sh 8hours

# Days
./schedule-flag-on.sh 1d
./schedule-flag-on.sh 7days

# Plain numbers (assumes minutes)
./schedule-flag-on.sh 45
```

---

## Best Practices

### 1. Always Snapshot First
```bash
# ❌ BAD - No snapshot
./turn-flag-off.sh

# ✅ GOOD - Snapshot first
./snapshot-flag.sh
./turn-flag-off.sh
```

### 2. Save Snapshot Filenames
```bash
# Save the snapshot filename for later
SNAPSHOT=$(ls -t flag-snapshot-*.json | head -1)
echo "Snapshot: $SNAPSHOT"

# Use it later
./restore-flag.sh "$SNAPSHOT" 5m
```

### 3. Test in Non-Production First
```bash
# Test in staging first
ENVIRONMENT="staging" ./snapshot-flag.sh
ENVIRONMENT="staging" ./schedule-flag-on.sh 2m

# Then do production
ENVIRONMENT="production" ./snapshot-flag.sh
ENVIRONMENT="production" ./schedule-flag-on.sh 2m
```

### 4. Document Schedule IDs
```bash
# Save schedule IDs for tracking
./schedule-flag-on.sh 5m | tee schedule-log.txt
# Schedule ID will be in schedule-log.txt
```

### 5. Set Calendar Reminders
When scheduling long-duration changes (days), set calendar reminders to verify execution.

---

## Troubleshooting Examples

### Problem: Wrong Time Scheduled

```bash
# List scheduled changes
curl -X GET \
  "https://app.launchdarkly.com/api/v2/projects/PROJECT/flags/FLAG/environments/ENV/scheduled-changes" \
  -H "Authorization: YOUR_TOKEN"

# Cancel wrong schedule
curl -X DELETE \
  "https://app.launchdarkly.com/api/v2/projects/PROJECT/flags/FLAG/environments/ENV/scheduled-changes/SCHEDULE_ID" \
  -H "Authorization: YOUR_TOKEN"

# Create new correct schedule
./restore-flag.sh flag-snapshot-*.json 10m
```

### Problem: Forgot to Take Snapshot

If you forgot to snapshot before making changes, you can manually create a "desired state" by:
1. Manually set flag to desired state in LaunchDarkly UI
2. Take snapshot now
3. Make your temporary changes
4. Use snapshot to restore later

---

## Summary

These scripts enable:
- ✅ Safe experimentation in production
- ✅ Automated time-based rollouts
- ✅ Zero-effort rollbacks
- ✅ Business hours automation
- ✅ Maintenance window management
- ✅ A/B test lifecycle management

Always remember: **Snapshot → Change → Restore**


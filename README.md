# LaunchDarkly Flag Backup and Restore Guide

A complete toolkit for safely managing temporary flag changes in LaunchDarkly using the **Snapshot + Restore** pattern.

## 🚀 Quick Start

1. **Install prerequisites:**
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt-get install jq curl
   ```

2. **Configure scripts with your details:**

   Open each script and replace these values:
   ```bash
   PROJECT_KEY="your-project-key"     # Your LaunchDarkly project key
   FLAG_KEY="your-flag-key"           # Your feature flag key
   ENVIRONMENT="production"           # Target environment
   API_TOKEN="your-api-token"         # Your LaunchDarkly API token
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

4. **Run the workflow:**
   ```bash
   # Step 1: Take a snapshot
   ./snapshot-flag.sh

   # Step 2: Schedule flag to turn ON (in 5 minutes)
   ./schedule-flag-on.sh

   # Step 3: Schedule restore (in 60 minutes)
   ./restore-flag.sh flag-snapshot-YYYYMMDD-HHMMSS.json 60
   ```

## 📁 What's Included

| File | Purpose | Status |
|------|---------|--------|
| `snapshot-flag.sh` | Captures current flag state to JSON | ✅ Production-tested |
| `schedule-flag-on.sh` | Schedules flag to turn ON | ✅ Production-tested |
| `restore-flag.sh` | Schedules flag to restore from snapshot | ✅ Production-tested |
| `turn-flag-off.sh` | Immediately turns flag OFF (bonus) | ✅ Production-tested |
| `LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md` | Complete documentation | 📖 Comprehensive guide |

## 🎯 Use Cases

- **Temporary Events**: Promotional banners, special offers, limited-time features
- **Scheduled Maintenance**: Toggle features during maintenance windows
- **Safe Testing**: Test production changes with guaranteed rollback
- **Time-Limited Features**: Campaign launches, seasonal features

## 📚 Documentation

See [LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md](./LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md) for:
- Complete workflow explanations
- Real-world examples
- Troubleshooting guide
- Best practices
- Security considerations
- Quick reference tables

## 🔒 Security

**Important:** These scripts contain placeholder API tokens. You must:
- ✅ Replace `your-api-token` with your actual LaunchDarkly API token
- ❌ Never commit real API tokens to version control
- ✅ Use environment variables for sensitive data
- ✅ Use service tokens (not personal tokens) for automation

### Using Environment Variables (Recommended)

Instead of hardcoding tokens in scripts, use environment variables:

```bash
# Set your API token as an environment variable
export LD_API_TOKEN="your-real-api-token"

# Then modify scripts to use it:
API_TOKEN="${LD_API_TOKEN}"
```

## 🔑 Getting Your API Token

1. Log in to LaunchDarkly
2. Go to: https://app.launchdarkly.com/settings/authorization
3. Create a new access token with **write permissions** for your target environment
4. Copy the token and use it in your scripts

## ⚡ Quick Example

**Scenario:** Enable a promotional banner for 2 hours

```bash
# Step 1: Snapshot current state
./snapshot-flag.sh
# Output: flag-snapshot-20260218-140000.json

# Step 2: Schedule to turn ON in 5 minutes
./schedule-flag-on.sh

# Step 3: Schedule to restore in 2 hours (120 minutes)
./restore-flag.sh flag-snapshot-20260218-140000.json 120
```

That's it! Your flag will:
- ✅ Turn ON automatically in 5 minutes
- ✅ Turn OFF automatically in 2 hours
- ✅ Restore to exact original state

## 📊 Script Details

### snapshot-flag.sh
- **Purpose**: Captures complete flag configuration
- **Output**: Timestamped JSON file with full flag state
- **Usage**: `./snapshot-flag.sh`

### schedule-flag-on.sh
- **Purpose**: Schedules flag to turn ON at future time
- **Default**: 5 minutes from execution
- **Customizable**: Change `MINUTES_FROM_NOW` variable
- **Usage**: `./schedule-flag-on.sh`

### restore-flag.sh
- **Purpose**: Schedules flag restoration from snapshot
- **Parameters**:
  - Snapshot file (required)
  - Minutes from now (optional, default: 60)
- **Usage**: `./restore-flag.sh <snapshot-file> <minutes>`

### turn-flag-off.sh (Bonus)
- **Purpose**: Immediately turns flag OFF (not scheduled)
- **Usage**: `./turn-flag-off.sh`

## 🛠️ Requirements

- **LaunchDarkly Account**: Enterprise plan (for scheduled changes)
- **API Token**: With write permissions for target environment
- **System Tools**:
  - `bash` (usually pre-installed)
  - `curl` (usually pre-installed)
  - `jq` (must install separately)

## 🧪 Testing These Scripts

All scripts in this repository have been production-tested with:
- Real LaunchDarkly flags
- Multiple environments
- Various timing scenarios
- Error handling validation

**Test Configuration Used:**
- Project: Enterprise project
- Flag Type: Boolean
- Environments: Production, Test
- Timing: 5 minutes to 2+ hours

## 📋 Best Practices

1. ✅ **Always snapshot first** - Never make changes without a backup
2. ✅ **Test in non-production** - Validate workflow in test environment first
3. ✅ **Monitor scheduled changes** - Check LaunchDarkly UI to verify execution
4. ✅ **Keep snapshots** - Archive snapshot files for audit trail
5. ✅ **Set calendar reminders** - Know when changes will execute
6. ✅ **Use descriptive comments** - Add clear comments in scheduled changes

## ❌ Common Pitfalls

1. ❌ Don't skip taking snapshots
2. ❌ Don't forget to schedule the restore
3. ❌ Don't use the same scheduled time for multiple changes
4. ❌ Don't ignore timezone differences (all times are UTC)
5. ❌ Don't delete snapshot files before restore completes

## 🐛 Troubleshooting

### "jq: command not found"
Install jq: `brew install jq` (macOS) or `sudo apt-get install jq` (Linux)

### "401 Unauthorized"
- Check your API token is valid
- Ensure token has write permissions

### "404 Not Found"
- Verify project key, flag key, and environment are correct
- Check flag exists in LaunchDarkly

### Scheduled change didn't execute
- Check LaunchDarkly audit log
- Verify scheduled change still exists
- Check timezone calculation

See the [complete troubleshooting guide](./LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md#troubleshooting) for more details.

## 📖 Additional Resources

- [LaunchDarkly API Documentation](https://apidocs.launchdarkly.com/)
- [Scheduled Flag Changes](https://docs.launchdarkly.com/home/organize/flags-deprecate#scheduled-flag-changes)
- [Complete Guide](./LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md)

## 🤝 Support

For issues or questions:
1. Check the [complete guide](./LAUNCHDARKLY-FLAG-BACKUP-AND-RESTORE-GUIDE.md)
2. Review LaunchDarkly documentation
3. Contact LaunchDarkly support

## 📄 License

This toolkit is provided as-is for use with LaunchDarkly. Please ensure compliance with your LaunchDarkly license agreement.

## ✨ Features

- ✅ **Production-tested** - All scripts validated with real flags
- ✅ **Error handling** - Comprehensive error checking and reporting
- ✅ **Flexible timing** - Customizable scheduling for any timeframe
- ✅ **Safe rollback** - Guaranteed restoration to original state
- ✅ **Audit trail** - All changes tracked in LaunchDarkly
- ✅ **Easy to use** - Simple bash scripts, no dependencies
- ✅ **Well-documented** - Comprehensive guide with examples

---

**Version:** 1.0
**Last Updated:** 2024
**LaunchDarkly API Version:** v2

🚀 Happy feature flagging!


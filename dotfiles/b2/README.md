# Backblaze B2 CLI Configuration

Command-line tool for interacting with Backblaze B2 cloud storage.

## Overview

The Backblaze B2 CLI provides access to B2 cloud storage for backup, file management, and cloud storage operations. B2 offers affordable cloud storage with an S3-compatible API.

## Installation

Installed via `install-b2.sh` script which:
- Installs `b2-tools` via Homebrew
- Configures shell integration
- Sets up helpful aliases and functions

### Python 3.14 Compatibility

If you're using Python 3.14, b2-tools 4.4.2 has a known buffer overflow bug in the `rst2ansi` library's terminal size detection. The `b2.sh` configuration automatically applies a workaround by setting `COLUMNS` and `LINES` environment variables to bypass the buggy code. This fix will be removed once b2-tools is updated for Python 3.14 compatibility.

## Configuration

### Account Setup

Before using B2, you need to authorize your account:

```bash
# Authorize with your account ID and application key
b2 authorize-account <account-id> <application-key>

# View your account info
b2 get-account-info
```

Your credentials are stored in `~/.b2_account_info` (automatically created).

### Environment Variables

You can also use environment variables for authorization:

```bash
export B2_ACCOUNT_ID="your-account-id"
export B2_APPLICATION_KEY="your-application-key"
```

Add these to your `.bash_env` or use a `.env` file for sensitive credentials.

## Shell Integration

The `b2.sh` configuration provides helpful aliases and functions:

### Aliases

- `b2ls` - Quick list of buckets
- `b2info` - Show account information
- `b2buckets` - List all buckets with details

### Functions

- `b2upload <bucket> <local-file> [remote-name]` - Upload a file
- `b2download <bucket> <remote-file> [local-file]` - Download a file
- `b2list <bucket> [prefix]` - List files in bucket
- `b2synchelp` - Show sync command examples and options

## Common Operations

### Bucket Management

```bash
# Create a new bucket
b2 create-bucket my-bucket allPrivate

# List all buckets
b2 list-buckets

# Delete a bucket (must be empty)
b2 delete-bucket my-bucket
```

### File Operations

```bash
# Upload a file
b2upload my-bucket ./document.pdf

# Upload with custom remote name
b2upload my-bucket ./local.txt remote-name.txt

# Download a file
b2download my-bucket remote.pdf ./local.pdf

# List files in bucket
b2list my-bucket

# List files with prefix
b2list my-bucket "backups/"

# Delete a file
b2 delete-file-version <file-name> <file-id>
```

### Sync Operations

```bash
# Upload directory to B2 (backup)
b2 sync /local/path b2://my-bucket/backups/

# Download from B2
b2 sync b2://my-bucket/backups/ /local/restore/

# Mirror with deletion
b2 sync --delete /local/path b2://my-bucket/mirror/

# Preview sync (dry run)
b2 sync --dryRun /local/path b2://my-bucket/backups/

# Sync with exclusions
b2 sync --excludeRegex "\.git/|node_modules/" \
  /local/path b2://my-bucket/backups/
```

## Best Practices

1. **Use Application Keys**: Create restricted application keys with limited permissions for specific buckets
2. **Lifecycle Rules**: Configure lifecycle rules to automatically delete or archive old files
3. **Encryption**: Enable server-side encryption for sensitive data
4. **Versioning**: B2 keeps file versions by default; use lifecycle rules to manage retention
5. **Cost Management**: Monitor storage and download costs; B2 charges for bandwidth
6. **Dry Runs**: Always test sync operations with `--dryRun` first

## Security Notes

- **Never commit credentials**: Keep `.b2_account_info` out of version control
- **Use restricted keys**: Create application keys with minimal required permissions
- **Bucket policies**: Set appropriate bucket privacy settings (allPrivate, allPublic)
- **Audit access**: Regularly review application keys and revoke unused ones

## Resources

- [B2 CLI Documentation](https://www.backblaze.com/b2/docs/quick_command_line.html)
- [B2 Pricing](https://www.backblaze.com/b2/cloud-storage-pricing.html)
- [B2 API Docs](https://www.backblaze.com/b2/docs/)

## Catppuccin Theme

B2 CLI is terminal-based and uses standard terminal colors. Ensure your terminal emulator is configured with the Catppuccin theme for consistent appearance.

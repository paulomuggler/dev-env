# b2.sh - Backblaze B2 CLI configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Check if b2 is installed
if ! command -v b2 >/dev/null 2>&1; then
  return
fi

# Python 3.14 Compatibility Fix
# b2-tools 4.4.2 with Python 3.14 has a buffer overflow bug in rst2ansi's
# terminal size detection. Setting these env vars bypasses the buggy code.
# This can be removed once b2-tools is updated for Python 3.14 compatibility.
export COLUMNS=${COLUMNS:-80}
export LINES=${LINES:-24}

# Convenient aliases for common b2 operations
alias b2ls='b2 ls'                      # List buckets
alias b2info='b2 get-account-info'      # Show account info
alias b2buckets='b2 list-buckets'       # List buckets (verbose)

# Functions for easier b2 usage

# Upload a file to B2
# Usage: b2upload <bucket-name> <local-file> [remote-name]
b2upload() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: b2upload <bucket-name> <local-file> [remote-name]"
    return 1
  fi

  local bucket="$1"
  local local_file="$2"
  local remote_name="${3:-$(basename "$local_file")}"

  b2 upload-file "$bucket" "$local_file" "$remote_name"
}

# Download a file from B2
# Usage: b2download <bucket-name> <remote-file> [local-file]
b2download() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: b2download <bucket-name> <remote-file> [local-file]"
    return 1
  fi

  local bucket="$1"
  local remote_file="$2"
  local local_file="${3:-$(basename "$remote_file")}"

  b2 download-file-by-name "$bucket" "$remote_file" "$local_file"
}

# List files in a B2 bucket
# Usage: b2list <bucket-name> [prefix]
b2list() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: b2list <bucket-name> [prefix]"
    return 1
  fi

  local bucket="$1"
  local prefix="${2:-}"

  if [[ -n "$prefix" ]]; then
    b2 ls --recursive "$bucket" "$prefix"
  else
    b2 ls --recursive "$bucket"
  fi
}

# Show b2 sync help (commonly used for backups)
b2synchelp() {
  cat <<'EOF'
B2 Sync Usage:
  b2 sync [options] <source> <destination>

Common examples:
  # Upload directory to B2
  b2 sync /local/path b2://bucket-name/remote/path

  # Download from B2 to local
  b2 sync b2://bucket-name/remote/path /local/path

  # Sync with delete (mirror)
  b2 sync --delete /local/path b2://bucket-name/remote/path

  # Dry run (preview changes)
  b2 sync --dryRun /local/path b2://bucket-name/remote/path

Options:
  --delete          Delete files in destination not in source
  --dryRun          Preview changes without making them
  --excludeRegex    Exclude files matching regex pattern
  --includeRegex    Only include files matching regex pattern
  --threads N       Number of parallel threads (default: 10)

EOF
}

export -f b2upload
export -f b2download
export -f b2list
export -f b2synchelp

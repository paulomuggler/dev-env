# pyenv Configuration

Configuration for [pyenv](https://github.com/pyenv/pyenv) - Python version management.

## What's Included

- `pyenv.sh`: Shell integration for pyenv initialization

## pyenv Overview

pyenv lets you easily switch between multiple versions of Python. It's simple, unobtrusive, and follows the UNIX tradition of single-purpose tools that do one thing well.

### Common Commands

```bash
# List available Python versions
pyenv install -l

# Install a Python version
pyenv install 3.12.0

# Set global Python version
pyenv global 3.12.0

# Set local Python version (per-directory)
pyenv local 3.11.0

# Show current Python version
pyenv version

# List installed versions
pyenv versions
```

### Build Dependencies

pyenv builds Python from source, so you need build dependencies:

**macOS:**
```bash
xcode-select --install
```

**Ubuntu/Debian:**
```bash
sudo apt-get install -y build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev
```

## Integration with Neovim

The Neovim Python provider uses a separate virtual environment at `~/.venvs/nvim` to avoid conflicts with pyenv-managed Python versions.

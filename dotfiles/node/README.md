# Node.js Configuration

Configuration for [Node.js](https://nodejs.org/) - JavaScript runtime and npm package manager.

## What's Included

- `node.sh`: Shell configuration for npm global bin path

## Node.js & npm Overview

Node.js is a JavaScript runtime built on Chrome's V8 engine. It comes with npm (Node Package Manager) for installing packages.

### Common Commands

```bash
# Check versions
node --version
npm --version

# Install package locally (in current project)
npm install <package>

# Install package globally
npm install -g <package>

# Execute package without installing
npx <command>

# Initialize a new project
npm init

# Install dependencies from package.json
npm install
```

### Global vs Local Packages

- **Local packages**: Installed in `./node_modules/` for the current project
- **Global packages**: Installed system-wide (use `-g` flag)

### Common Global Packages

```bash
npm install -g typescript    # TypeScript compiler
npm install -g ts-node       # TypeScript execution
npm install -g eslint        # JavaScript linter
npm install -g prettier      # Code formatter
npm install -g nodemon       # Auto-restart for development
```

## Alternative: nvm (Node Version Manager)

If you need multiple Node.js versions, consider installing [nvm](https://github.com/nvm-sh/nvm) instead. It works like pyenv/rbenv for Node.js.

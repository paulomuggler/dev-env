# DevEnv Implementation Planning

## Project Status: **PHASE 1 - SETUP INFRASTRUCTURE**

### Current State
- [x] Core documentation created (CLAUDE.md, SETUP.md, PLANNING.md)
- [x] Project structure defined
- [x] Tool research completed
- [x] oldfiles analyzed and gitignored
- [ ] **Next**: Begin Phase 1 implementation

## Implementation Roadmap

### Phase 1: Setup Infrastructure & Core Tools
**Goal**: Reproducible, modular setup with validation and proper error handling

#### 1.1 Foundation Setup
- [ ] Create directory structure (`install-scripts/`, `libs/`, `dotfiles/`)
- [ ] Implement shared utility libraries:
  - [ ] `libs/logger.sh` - Integrate bashlog or custom logging
  - [ ] `libs/colors.sh` - Terminal color utilities
  - [ ] `libs/utils.sh` - Common validation functions
- [ ] Create `.stowrc` configuration file
- [ ] Set up `.env.example` template

#### 1.2 Core Installation Scripts
- [ ] `install-scripts/install-homebrew.sh` - Homebrew setup with validation
- [ ] `install-scripts/install-stow.sh` - GNU Stow installation
- [ ] `install-scripts/install-git.sh` - Git setup and configuration
- [ ] `install-scripts/install-core-tools.sh` - Essential CLI tools (fzf, ripgrep, etc.)
- [ ] `install-scripts/install-languages.sh` - Python, Node.js, Ruby environments

#### 1.3 Configuration Packages (Stow)
- [ ] `dotfiles/shell/` - Bash configuration package
  - [ ] Parse and import from oldfiles (not straight copy - extract tool-specific settings)
  - [ ] Create dedicated `.bash_path` file for all PATH modifications
  - [ ] Distribute tool-specific configs to appropriate packages (e.g., starship settings)
  - [ ] Add XDG compliance and environment variables
  - [ ] Include custom bin scripts
- [ ] `dotfiles/git/` - Git configuration package
- [ ] `dotfiles/starship/` - Prompt configuration package with Catppuccin theme

#### 1.4 Fonts & Theming Setup
- [ ] `install-scripts/install-fonts.sh` - Install Nerd Fonts (FiraCode Nerd Font)
- [ ] Configure Catppuccin theme across all tools
- [ ] Font configuration for terminal and editors

#### 1.5 Basic Neovim Setup
- [ ] `install-scripts/install-neovim.sh` - Neovim and language providers
- [ ] `dotfiles/nvim/` - Default Neovim configuration package
- [ ] `dotfiles/lazyvim/` - LazyVim configuration package with Catppuccin theme
- [ ] Python venv setup for each configuration (nvim, lazyvim only)
- [ ] Handle existing config import gracefully

#### 1.6 Main Orchestrator
- [ ] `setup.sh` - Main script that coordinates all installations
  - [ ] Progress tracking and clear output
  - [ ] Error handling and rollback capabilities
  - [ ] Dependency order management
  - [ ] Platform detection

#### 1.7 Testing & Validation
- [ ] Test on clean macOS environment
- [ ] Validate idempotency (safe re-run)
- [ ] Verify all tools work after installation
- [ ] Document any manual steps required

### Phase 2: LLM Integration & Tmux Workspace
**Goal**: Functional LLM workflow with tmux-based workspace

#### 2.1 Tmux Enhancement
- [ ] `install-scripts/install-tmux.sh` - Tmux with plugins
- [ ] `dotfiles/tmux/` - Tmux configuration package
  - [ ] Enhanced visual settings
  - [ ] Plugin management (tmux-resurrect, tmux-continuum)
  - [ ] Custom keybindings
  - [ ] Session management utilities
- [ ] Research and document useful tmux plugins

#### 2.2 Terminal Enhancement (iTerm2 focused)
- [ ] iTerm2 configuration and optimization
- [ ] Terminal keybinding setup
- [ ] Integration with tmux workflow

#### 2.3 LLM CLI Tools
- [ ] Research available LLM CLI chat clients
- [ ] `install-scripts/install-llm-cli.sh` - LLM CLI installation
- [ ] Configure authentication and API key management
- [ ] Test basic functionality of each CLI

#### 2.4 Workspace Implementation
- [ ] Design 3-pane tmux layout (LLM left | nvim right | prompt buffer bottom)
- [ ] Create custom tmux session command
- [ ] Implement directory-based workspace opening
- [ ] Create sample scripts for tmux pane piping

#### 2.5 Prompt Buffer Workflow
- [ ] Implement nvim buffer → tmux pane piping scripts
- [ ] Add keybindings for sending prompts
- [ ] Support visual mode selections
- [ ] Test workflow with multiple LLM CLIs
- [ ] Document workflow in WORKSPACE.md

#### 2.6 Session Management
- [ ] Custom commands for workspace creation
- [ ] Session saving and restoration
- [ ] Directory-specific workspace launching
- [ ] Integration with existing tmux session management

### Phase 3: Advanced Features (Future)
**Goal**: Git-based conversation tracking and enhanced automation

#### 3.1 Conversation Branching Infrastructure
- [ ] Design git-based conversation storage (`.llm-history/` approach)
- [ ] Implement auto-commit functionality (toggleable)
- [ ] Create conversation context reset commands
- [ ] Basic conversation branching and merge

#### 3.2 Working Tree Integration
- [ ] Toggleable working file state tracking
- [ ] Automatic working tree commits on LLM changes
- [ ] Context reset with working tree restoration
- [ ] Conflict resolution strategies

#### 3.3 Enhanced Automation
- [ ] Advanced tmux session management
- [ ] Workspace templates for different project types
- [ ] Integration with git workflow
- [ ] Enhanced debugging and logging

## Current Action Items

### Immediate Next Steps (This Session)
1. **Create directory structure** - Set up `install-scripts/`, `libs/`, `dotfiles/`
2. **Implement shared utilities** - Start with logger.sh using bashlog research
3. **Create first install script** - Begin with install-homebrew.sh as foundation
4. **Set up stow configuration** - Create .stowrc with dot_ notation
5. **Create first stow package** - Start with shell configuration

### Dependencies & Blockers
- **Bash library choice**: Use bashlog based on research
- **Configuration parsing**: Need strategy for extracting tool-specific settings from oldfiles
- **PATH management**: Implement dedicated .bash_path file approach
- **Existing config handling**: Develop graceful import strategy for stow conflicts
- **Tmux plugins**: Research needed for plugin recommendations
- **LLM CLI availability**: Need to survey current LLM CLI options
- **Testing environment**: May need clean macOS VM or container for testing

### Success Criteria

#### Phase 1 Complete When:
- [ ] Fresh macOS system can run `./setup.sh` and get working dev environment
- [ ] All tools listed in SETUP.md are properly installed and configured
- [ ] Neovim configurations (default, LazyVim) all work correctly
- [ ] Stow packages correctly manage all dotfiles
- [ ] Setup is idempotent and can be safely re-run

#### Phase 2 Complete When:
- [ ] Custom tmux workspace can be launched for any directory
- [ ] LLM CLI tools are installed and configured
- [ ] Prompt buffer workflow functions (nvim → LLM CLI via tmux piping)
- [ ] Visual mode selections can be sent to LLM CLI
- [ ] Session management works reliably

#### Phase 3 Complete When:
- [ ] Git conversation branching is functional
- [ ] Context can be reset to any conversation point
- [ ] Working tree state integration is reliable
- [ ] Advanced automation features are stable

## Risk Mitigation

### Technical Risks
- **Complexity explosion**: Keep modular, focus on MVP for each phase
- **Platform incompatibility**: Test early and often on target platform
- **Dependency conflicts**: Isolate installations and use proper version pinning
- **Stow conflicts**: Backup existing configs and handle gracefully

### Process Risks
- **Feature creep**: Stick to phase goals, document future ideas separately
- **Testing gaps**: Validate each component before moving to next phase
- **Documentation drift**: Keep docs updated as implementation progresses

## Notes & Context

### Key Decisions Made
- **Platform**: macOS first, future platforms TBD
- **Package manager**: Homebrew ecosystem
- **Shell**: Bash (not zsh)
- **Terminal**: iTerm2 (not Kitty/WezTerm for now)
- **Editor**: Neovim with LazyVim (not AstroNvim for now)
- **Theme**: Catppuccin across all tools
- **Font**: FiraCode Nerd Font
- **Configuration management**: GNU Stow with dot_ notation
- **PATH management**: Dedicated .bash_path file
- **Logging**: Bashlog library for lightweight logging
- **Architecture**: Modular scripts with shared utilities

### Open Questions
- **Branch strategy**: Single branch with platform detection vs separate platform branches?
- **Testing framework**: When to introduce BATS or other testing?
- **Plugin management**: How to handle tmux/neovim plugin updates?
- **Secret management**: Enhance beyond simple .env file approach?

### Future Considerations
- **Multi-user support**: Support for shared team configurations
- **Docker integration**: Containerized development environments
- **CI/CD**: Automated testing of installation scripts
- **Package management**: Custom package definition and dependency resolution
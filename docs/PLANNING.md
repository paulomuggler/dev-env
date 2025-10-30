# DevEnv Implementation Planning

## Project Status: **PHASE 2 - LLM INTEGRATION** (In Progress)

### Current State
- [x] Core documentation created (CLAUDE.md, SETUP.md, PLANNING.md, WISHLIST.md)
- [x] Project structure defined
- [x] Tool research completed
- [x] oldfiles analyzed and gitignored
- [x] **Phase 1 Complete**: Setup infrastructure implemented and working
- [x] Core tools and dotfiles all configured
- [x] Image-aware LLM send feature spec'd (ready for implementation)
- [ ] **Next**: Complete Phase 2 - Workspace implementation and image send feature

## Implementation Roadmap

### Phase 1: Setup Infrastructure & Core Tools
**Goal**: Reproducible, modular setup with validation and proper error handling

#### 1.1 Foundation Setup
- [x] Create directory structure (`install-scripts/`, `libs/`, `dotfiles/`)
- [x] Implement shared utility libraries:
  - [x] `libs/logger.sh` - Integrate bashlog or custom logging
  - [x] `libs/colors.sh` - Terminal color utilities (via bash-utility)
  - [x] `libs/utils.sh` - Common validation functions
  - [x] `libs/platform.sh` - Platform detection utilities
  - [x] `libs/linker.sh` - Library sourcing helper
- [x] Create `.stowrc` configuration file (`dotfiles/stow/dot-stowrc`)
- [ ] Set up `.env.example` template

#### 1.2 Core Installation Scripts
- [x] `install-scripts/install-homebrew.sh` - Homebrew setup with validation
- [x] `install-scripts/install-stow.sh` - GNU Stow installation
- [x] `install-scripts/install-git.sh` - Git setup and configuration
- [x] `install-scripts/install-core-tools.sh` - Essential CLI tools (fzf, ripgrep, bat, eza, fd, bottom, yazi, etc.)
- [x] `install-scripts/install-node.sh` - Node.js environment
- [x] Additional tool scripts: lynx, xz, zstd, duf, sd, starship, grok-cli

#### 1.3 Configuration Packages (Stow)
- [x] `dotfiles/shell/` - Bash configuration package
  - [x] Parse and import from oldfiles (not straight copy - extract tool-specific settings)
  - [x] Create dedicated `.bash_path` file for all PATH modifications
  - [x] Distribute tool-specific configs to appropriate packages (e.g., starship settings)
  - [x] Add XDG compliance and environment variables
  - [x] Include custom bin scripts
- [x] `dotfiles/git/` - Git configuration package
- [x] `dotfiles/starship/` - Prompt configuration package with Catppuccin theme
- [x] Additional packages created: tmux, nvim, yazi, bat, fzf, ripgrep, eza, bottom, fd, zoxide, lazygit, gh, claude, iterm2, aerospace, pyenv, rbenv, node, homebrew, stow

#### 1.4 Fonts & Theming Setup
- [x] `install-scripts/install-nerd-fonts.sh` - Install Nerd Fonts (FiraCode Nerd Font)
- [x] Configure Catppuccin theme across all tools
- [x] Font configuration for terminal and editors

#### 1.5 Basic Neovim Setup
- [x] `install-scripts/install-nvim.sh` - Neovim and language providers
- [x] `dotfiles/nvim/` - Default Neovim configuration package
- [x] `dotfiles/lazyvim/` - LazyVim configuration package with Catppuccin theme
- [x] Python venv setup for each configuration (nvim, lazyvim only)
- [x] Handle existing config import gracefully

#### 1.6 Main Orchestrator
- [x] `setup.sh` - Main script that coordinates all installations
  - [x] Progress tracking and clear output
  - [x] Error handling and rollback capabilities
  - [x] Dependency order management
  - [x] Platform detection

#### 1.7 Testing & Validation
- [ ] Test on clean macOS environment (on hold - batch testing later)
- [ ] Validate idempotency (safe re-run) (on hold - batch testing later)
- [x] Verify all tools work after installation
- [x] Document any manual steps required

### Phase 2: LLM Integration & Tmux Workspace
**Goal**: Functional LLM workflow with tmux-based workspace

#### 2.1 Tmux Enhancement
- [x] `install-scripts/install-tmux.sh` - Tmux with plugins (via Homebrew, handled by core tools)
- [x] `dotfiles/tmux/` - Tmux configuration package
  - [x] Enhanced visual settings
  - [x] Plugin management (tmux-resurrect, tmux-continuum)
  - [x] Custom keybindings
  - [x] Session management utilities
- [x] Research and document useful tmux plugins

#### 2.2 Terminal Enhancement (iTerm2 focused)
- [x] iTerm2 configuration and optimization
- [x] Terminal keybinding setup
- [x] Integration with tmux workflow

#### 2.3 LLM CLI Tools
- [x] Research available LLM CLI chat clients
- [x] `install-scripts/install-grok-cli.sh` - Grok CLI installation
- [x] `dotfiles/claude/` - Claude Code configuration package
- [x] Configure authentication and API key management
- [x] Test basic functionality of each CLI

#### 2.4 Workspace Implementation (See external/lazy-llm/)
- [x] Design 3-pane tmux layout (LLM left | nvim right | prompt buffer bottom)
- [x] Create custom tmux session command (`lazy-llm-bin/`)
- [x] Implement directory-based workspace opening
- [x] Create sample scripts for tmux pane piping

#### 2.5 Prompt Buffer Workflow (See external/lazy-llm/)
- [x] Implement nvim buffer → tmux pane piping scripts (`llm-send-bin/`)
- [x] Add keybindings for sending prompts (`nvim-llm-send-plugin/`)
- [x] Support visual mode selections
- [x] Test workflow with multiple LLM CLIs
- [x] Git integration for conversation tracking (`nvim-git-plugin/`)
- [ ] Document workflow in WORKSPACE.md (partial - see lazy-llm/docs/)

#### 2.6 Session Management (See external/lazy-llm/)
- [x] Custom commands for workspace creation (`install.sh`)
- [x] Session saving and restoration (via tmux-resurrect)
- [x] Directory-specific workspace launching
- [x] Integration with existing tmux session management

#### 2.7 Image-Aware LLM Send (NEW)
- [x] Research clipboard image handling in LLM TUIs (Claude Code, Gemini CLI)
- [x] Research Neovim clipboard image plugins
- [x] Design memory-only image buffer architecture
- [x] Document feature specification in `docs/IMAGE_SEND_FEATURE.md`
- [ ] Implement `llm-image-buffer.lua` module (Phase 1)
- [ ] Enhance `llm-send.lua` with image-aware send logic (Phase 2)
- [ ] Add multi-image support (Phase 3)
- [ ] Implement error handling and edge cases (Phase 4)
- [ ] Polish and documentation (Phase 5)

### Blocked/Deferred Features (See WISHLIST.md)

#### Mode-Specific LLM Send
- **Status**: 🔴 Blocked - Waiting for Claude Code CLI flag support
- **What**: Send prompts to Claude in specific modes (Normal/Plan/Auto-Accept) via keymaps
- **Blocker**: No `--mode` CLI flag available; settings require restart; context fragmentation
- **Documentation**: `docs/MODE_SPECIFIC_SEND.md`, `docs/WISHLIST.md`
- **Watch**: [anthropics/claude-code#2667](https://github.com/anthropics/claude-code/issues/2667)

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

### Immediate Next Steps
1. **Implement image-aware LLM send** - Begin Phase 1: Core Image Buffer (MVP)
   - Create `llm-image-buffer.lua` module in external/lazy-llm/
   - Implement clipboard image capture and storage
   - Add keymap for inserting image markers
   - Integrate with existing llm-send workflow
2. **Consolidate workspace documentation** - Merge lazy-llm/docs/ into WORKSPACE.md
3. **Batch testing phase** (deferred) - Validate setup.sh idempotency on clean environment

### Dependencies & Blockers
- ✅ **Bash library choice**: Using bashlog and bash-utility
- ✅ **Configuration parsing**: Tool-specific extraction pattern implemented
- ✅ **PATH management**: Dedicated .bash_path file implemented
- ✅ **Existing config handling**: Graceful import strategy implemented
- ✅ **Tmux plugins**: Research complete, plugins configured
- ✅ **LLM CLI availability**: Claude Code and Grok CLI integrated
- ✅ **.stowrc**: Created in dotfiles/stow/dot-stowrc
- **Testing environment**: Clean macOS VM testing deferred to batch validation
- **Mode-specific send**: Blocked pending upstream CLI flag (see WISHLIST.md)

### Success Criteria

#### Phase 1 Complete When:
- [x] Fresh macOS system can run `./setup.sh` and get working dev environment
- [x] All tools listed in SETUP.md are properly installed and configured
- [x] Neovim configurations (default, LazyVim) all work correctly
- [x] Stow packages correctly manage all dotfiles
- [x] .stowrc created for proper --dotfiles flag handling
- [ ] Setup is idempotent and can be safely re-run (on hold - batch testing later)

**Status**: ✅ **COMPLETE** (testing deferred to batch validation phase)

#### Phase 2 Complete When:
- [x] Custom tmux workspace can be launched for any directory
- [x] LLM CLI tools are installed and configured
- [x] Prompt buffer workflow functions (nvim → LLM CLI via tmux piping)
- [x] Visual mode selections can be sent to LLM CLI
- [x] Git-based conversation tracking implemented
- [ ] Image-aware prompt sending implemented and tested
- [x] Session management works reliably
- [ ] Workspace documentation complete (partial - consolidated in WORKSPACE.md pending)

**Status**: 🟢 **NEARLY COMPLETE** (lazy-llm fully functional, only image-send and docs pending)

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
- **Configuration management**: GNU Stow with dot- notation (--dotfiles flag)
- **PATH management**: Dedicated .bash_path file
- **Logging**: Bashlog library for lightweight logging
- **Architecture**: Modular scripts with shared utilities
- **Image workflow**: Memory-only approach (no disk I/O for clipboard images)
- **Mode-specific send**: Deferred pending upstream CLI flag support

### Open Questions
- **Branch strategy**: Single branch with platform detection vs separate platform branches?
- **Testing approach**: Manual testing vs automated testing needs
- **Plugin management**: How to handle tmux/neovim plugin updates?
- **Secret management**: Enhance beyond simple .env file approach?

### Future Considerations
- **Multi-user support**: Support for shared team configurations
- **Docker integration**: Containerized development environments
- **CI/CD**: Automated testing of installation scripts
- **Package management**: Custom package definition and dependency resolution
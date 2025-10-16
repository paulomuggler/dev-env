# Future Improvements

This document tracks potential enhancements and tools to add to DevEnv.

## macOS System Automation

### Hammerspoon
- **Description**: Powerful automation tool for macOS
- **URL**: https://www.hammerspoon.org/
- **Use cases**:
  - Window management with Lua scripts
  - Keyboard shortcuts and hotkeys
  - Application launching and switching
  - Custom menubar items
  - System event handling
- **Why add**: Highly scriptable, lighter than Karabiner for some use cases
- **Priority**: High
- **Notes**: Would complement AeroSpace for complete window/system control

### Karabiner-Elements
- **Description**: Powerful keyboard customizer for macOS
- **URL**: https://karabiner-elements.pqrs.org/
- **Use cases**:
  - Complex key remapping
  - Hyper key setup
  - Application-specific keybindings
  - Vim-style navigation system-wide
  - Mouse button remapping
- **Why add**: Industry standard for keyboard customization on macOS
- **Priority**: High
- **Notes**: Often used together with Hammerspoon

## Broken/Deprecated Tools

### dog (DNS lookup)
- **Status**: DISABLED - brew formula page dead
- **Alternative**: Use `dig` (built-in) or `doggo` (https://github.com/mr-karan/doggo)
- **Location**: `install-scripts/install-dog.sh` exists but commented out in setup.sh
- **Action**: Consider replacing with `doggo` if it proves stable

## Potential Tool Additions

### Terminal & Shell

- **zellij** - Alternative to tmux with better defaults
- **atuin** - Shell history sync and search
- **starship presets** - Pre-configured starship themes
- **oh-my-bash** - Bash framework (alternative approach)

### Development Tools

- **direnv** - Environment variable management per directory
- **just** - Command runner (Makefile alternative)
- **mise** / **asdf** - Universal version manager (alternative to *env tools)
- **delta** - Better git diff viewer
- **gitui** - Alternative Git TUI to lazygit
- **gh-dash** - GitHub CLI dashboard

### File & Text Processing

- **miller** - CSV/JSON/etc data processing
- **fx** - Interactive JSON viewer
- **yq** - YAML processor (like jq for YAML)
- **gron** - Make JSON greppable
- **hexyl** - Hex viewer

### System Monitoring

- **procs** - Modern `ps` replacement
- **bandwhich** - Network bandwidth monitor
- **zenith** - Alternative system monitor

### Network Tools

- **httpie** - User-friendly HTTP client (alternative to xh)
- **curlie** - curl with httpie syntax
- **gping** - Ping with graph
- **trippy** - Network diagnostic tool

### Productivity

- **tldr** - Simplified man pages
- **cheat** - Interactive cheatsheets
- **navi** - Interactive cheatsheet tool
- **hstr** - Shell history suggest box

### macOS-Specific

- **mas** - Mac App Store CLI
- **mackup** - Application settings backup
- **dockutil** - Dock management
- **m-cli** - Swiss army knife for macOS

## Configuration Improvements

### Tmux
- [ ] Add more custom layouts for different workflows
- [ ] Create session templates (dev, writing, ops, etc.)
- [ ] Integrate with lazy-llm more deeply
- [ ] Add tmux-fingers for copy mode enhancements

### Neovim
- [ ] Document custom keybindings
- [ ] Add project-specific configurations
- [ ] Create snippets for common patterns
- [ ] LSP configuration documentation

### Shell
- [ ] Add more useful aliases
- [ ] Create project-specific shell functions
- [ ] Add completion scripts for custom tools
- [ ] Improve prompt with more git info

## Infrastructure

### Testing
- [ ] Create test suite for install scripts
- [ ] Add CI/CD for validation
- [ ] Test on fresh VM/container
- [ ] Cross-platform testing automation

### Documentation
- [ ] Video walkthrough of setup
- [ ] Troubleshooting guide expansion
- [ ] Common workflows documentation
- [ ] Performance tuning guide

### Modularity
- [ ] Make phases more granular
- [ ] Add tool categories/tags
- [ ] Allow custom tool selection
- [ ] Profile-based installation (minimal, full, dev-specific)

## Integration Ideas

### LLM Workflow
- [ ] Claude Code integration with tmux sessions
- [ ] Context management scripts
- [ ] Conversation branching utilities
- [ ] Prompt templates library

### Git Workflow
- [ ] Pre-commit hooks setup
- [ ] Commit message templates
- [ ] Git aliases for common workflows
- [ ] Branch naming conventions

### Project Templates
- [ ] Starter templates for different languages
- [ ] Docker-based dev environments
- [ ] VS Code integration (optional)
- [ ] Project initialization scripts

---

## Contributing Ideas

If you have suggestions for improvements, add them to the appropriate section above with:
- Brief description
- Link to project (if applicable)
- Why it would be useful
- Priority estimate (High/Medium/Low)

## Notes

- Keep the tool list focused on quality over quantity
- Prefer tools that are actively maintained
- Consider platform compatibility
- Document any known issues or limitations
- Test thoroughly before adding to main setup

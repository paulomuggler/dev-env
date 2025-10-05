# Bottom Configuration

Yet another cross-platform graphical process/system monitor. A modern, customizable alternative to top/htop.

## Features

- **CPU Monitoring**: Per-core usage with graphs
- **Memory Tracking**: RAM and swap usage
- **Process Management**: Kill, search, and sort processes
- **Network Stats**: Upload/download rates
- **Disk Usage**: Read/write rates per disk
- **Temperature**: CPU and system temperatures
- **Battery**: Battery percentage and status (on laptops)

## Configuration Files

- `.config/bottom/bottom.toml` - Main configuration with layout, colors, and behavior

## Shell Integration

The `bottom.sh` file provides convenient aliases:

### Basic Aliases
- `btm` - Launch bottom
- `top` - Use bottom instead of top
- `htop` - Use bottom instead of htop

### Mode Aliases
- `btmbasic` - Simplified interface
- `btmtree` - Show process tree
- `btmavg` - Show average CPU usage
- `btmgroup` - Group processes by name

### Update Rate Aliases
- `btm500` - Fast refresh (500ms)
- `btm2` - Slow refresh (2s)

### Focus Aliases
- `btmcpu` - Start focused on CPU widget
- `btmmem` - Start focused on memory widget
- `btmproc` - Start focused on process widget

## Configuration Highlights

### Display Settings
- 1-second update rate
- Celsius for temperatures
- Battery monitoring enabled
- Mouse support enabled

### Widget Layout
Default layout includes:
1. CPU usage graph
2. Memory usage
3. Network activity
4. Disk I/O
5. Temperature sensors
6. Process list (default focus)

## Key Bindings

### Navigation
- `Tab` / `Shift+Tab` - Cycle between widgets
- `↑/↓` or `j/k` - Navigate lists
- `gg` / `G` - Jump to top/bottom of list
- `Home` / `End` - First/last entry

### Process Management
- `/` - Search processes
- `dd` - Kill selected process (with confirmation)
- `c` - Sort by CPU
- `m` - Sort by memory
- `p` - Sort by PID
- `n` - Sort by name

### Display
- `+/-` - Zoom in/out on graphs
- `=` - Reset zoom
- `e` - Toggle process grouping
- `t` - Toggle process tree mode
- `?` - Show help

### General
- `q` - Quit
- `Ctrl+c` - Quit

## Usage Examples

```bash
# Basic usage
btm

# Simplified interface
btmbasic

# Fast refresh rate
btm500

# Show process tree
btmtree

# Focus on CPU usage
btmcpu
```

## Comparison with Other Tools

### vs top
- Graphical interface with mouse support
- Better visualization with graphs
- More intuitive navigation

### vs htop
- Written in Rust (faster, safer)
- More detailed graphs
- Network and disk monitoring built-in
- Better customization via config file

## Documentation

- [Bottom GitHub](https://github.com/ClementTsang/bottom)
- [User Documentation](https://clementtsang.github.io/bottom/)
- [Sample Configs](https://github.com/ClementTsang/bottom/tree/main/sample_configs)

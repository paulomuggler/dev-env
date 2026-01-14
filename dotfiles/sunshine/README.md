# Sunshine Configuration

Low-latency game streaming server for remote desktop access.

## Overview

Sunshine + Moonlight provides a low-latency remote desktop experience, similar to Parsec or Steam Remote Play. This setup is optimized for:

- **AMD Radeon 780M iGPU** (Beelink SER9 / AMD Ryzen 7)
- **VAAPI hardware encoding** for efficient, low-latency streaming
- **Wayland/Hyprland** compositor capture
- **Tailscale** network for secure remote access

## First-Time Setup

1. **Install Sunshine** (via install script or AUR)
2. **Start Sunshine**: `systemctl --user start sunshine`
3. **Open web UI**: https://localhost:47990
4. **Set username/password** for pairing
5. **Pair Moonlight client** using PIN

## Client Setup (Moonlight)

1. Install Moonlight on your client device
2. Enter the Tailscale IP of your Omarchy machine
3. Enter the PIN shown in Sunshine's web UI
4. Connect and enjoy!

## Configuration

Key settings in `~/.config/sunshine/sunshine.conf`:

| Setting | Value | Notes |
|---------|-------|-------|
| `encoder` | `vaapi` | AMD hardware encoding |
| `capture` | `wlr` | Wayland/Hyprland capture |
| `fps` | `60` | Target framerate |

## Network Security

For security, Sunshine should ideally only listen on the Tailscale interface:

1. Find your Tailscale IP: `tailscale ip -4`
2. Configure Sunshine to bind only to that interface
3. Ensure your firewall blocks ports 47989-47990 on public interfaces

## Troubleshooting

### Black screen / No capture
- Ensure `wlr` capture is working: check Sunshine logs
- Fallback: try `capture = kms` in config
- Verify `/dev/dri/renderD128` exists for VAAPI

### High latency
- Check network: Tailscale should show <50ms latency
- Try reducing resolution or bitrate
- Ensure hardware encoding is working (check Sunshine logs for VAAPI)

### Audio issues
- Check `audio_sink` setting
- Ensure PipeWire/PulseAudio is running

## Systemd Service

Sunshine runs as a user service:

```bash
# Enable auto-start
systemctl --user enable sunshine

# Start now
systemctl --user start sunshine

# Check status
systemctl --user status sunshine

# View logs
journalctl --user -u sunshine -f
```

## Files

- `~/.config/sunshine/sunshine.conf` - Main configuration
- Credentials stored in Sunshine's internal database (set via web UI)

<div align="center">
  
<img src="readme_assets/logo.png" alt="Logo" width="300" height="129">

---

  <h3 align="center">Hypr Background Manager</h3>

  <p align="center">
    Dynamic wallpaper manager for Hyprland with multiple service backends and trigger modes.
    <br />
    <br />
    <a href="https://github.com/joao-paulo-santos/hypr-bg-manager/issues">Report Bug</a>
    ·
    <a href="https://github.com/joao-paulo-santos/hypr-bg-manager/issues">Request Feature</a>
  </p>
</div>

## Installation

### From AUR
```bash
yay -S hypr-bg-manager
# or
paru -S hypr-bg-manager
```

### Manual Installation
```bash
git clone https://github.com/joao-paulo-santos/hypr-bg-manager.git
cd hypr-bg-manager
sudo make install
```

### Local Usage (No Installation)
```bash
git clone https://github.com/joao-paulo-santos/hypr-bg-manager.git
cd hypr-bg-manager
./hypr-bg-manager.sh
```

## Quick Start

```bash
# Default: global random wallpapers on timer using swww
hypr-bg-manager -i global -t timer

# Per-workspace wallpapers on workspace change using swaybg
hypr-bg-manager -s swaybg -i pw -t socket

# Per-workspace wallpapers on timer (changes every 60s)
hypr-bg-manager -i pw -t timer --interval 60
```

## Hyprland Integration

Add to your `hyprland.conf`:

```bash
# Start wallpaper service (choose one)
exec-once = swww-deamon

# Start background manager (default: global timer mode)
exec-once = hypr-bg-manager -i global -t timer
# exec-once = hypr-bg-manager -s swaybg -i pw -t socket
# exec-once = hypr-bg-manager -s hyprpaper -i pw -t both --interval 120
```

## Features

- **Multiple Services**: swww, hyprpaper, swaybg, mpvpaper
- **Trigger Modes**: workspace change, timer, or both
- **Image Sources**: per-workspace or global random
- **Auto-format Detection**: service-specific supported formats

## Directory Structure

```
~/Pictures/wallpapers/
├── work/       # "work" workspace wallpapers
├── gaming/     # "gaming" workspace wallpapers
└── shared/     # Global mode wallpapers & fallback
```

## Options

| Flag | Description | Values |
|------|-------------|---------|
| `-d, --dir` | Wallpaper directory | Path (default: `~/.config/hypr/bg`) |
| `-i, --img` | Image source | `pw` (per-workspace), `global` |
| `-t, --trigger` | Trigger type | `socket`, `timer`, `both` |
| `-s, --service` | Wallpaper service | `swww`, `hyprpaper`, `swaybg`, `mpvpaper` |
| `-e, --extra-flags` | Service flags | Custom flags |
| `--interval` | Timer interval | Seconds (default: 30) |

## Examples

```bash
# Use hyprpaper with custom directory
hypr-bg-manager -s hyprpaper -d ~/Pictures/walls

# mpvpaper with videos, timer mode
hypr-bg-manager -s mpvpaper -t timer --interval 45

# swaybg with extra flags
hypr-bg-manager -s swaybg -e "-m stretch"
```

## Service Notes

- **swww**: Supports GIF animations, fastest transitions
- **hyprpaper**: Native Hyprland, requires preloading
- **swaybg**: Lightweight, good for minimal setups  
- **mpvpaper**: Supports videos and animated wallpapers
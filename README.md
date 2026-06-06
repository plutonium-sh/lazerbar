# lazerbar

a Quickshell config based on the top bar from osu!lazer,
btw this is Hyprland only because it's lwk the best twm ever

## features

- **top bar** -- the osu!lazer top bar, now on your Hyprland desktop. workspaces, system tray, clock, session timer, analog clock, media controls, volume scroll, audio visualizer
- **app launcher** -- full-screen overlay search with desktopentries integration, math evaluation via `qalc` (trig, logs, everything), and a globalshortcut keybind
- **control center** -- calendar, weather, battery (upower), notification history, pomodoro timer, brightness slider (ddcutil), wifi manager, system info (hostname/distro/kernel/uptime),
- **settings** -- toggle bar elements, pick wallpapers from osu!/konachan, customize colors (accent, bg, surface, border, workspace), customizable colors, bar opacity, audio mixer with spectrum visualizer
- **wallpaper** -- wallpaper, also a konachan/osu! fetcher in settings
- **lockscreen** -- PAM auth, this lwk just exists 👍
- **notifications** -- dopamine.

## required

- [Hyprland](https://hyprland.org/)
- [Quickshell](https://quickshell.org/)
- [Torus font](https://github.com/ppy/osu-web/tree/master/resources/fonts/torus)
- `pipewire` / `libpipewire` -- audio
- MPRIS-compatible D-Bus service -- media player controls
- `freedesktop.org` notifications D-Bus service
- PAM (Pluggable Authentication Modules) -- lockscreen

## optional

| Dependency                | Used for                              |
| ------------------------- | ------------------------------------- |
| `nmcli` (networkmanager)  | wifi radio toggle                     |
| `ddcutil`                 | monitor brightness control via ddc/ci |
| `qalc` (libqalculate)     | advanced math in the app launcher     |
| `wl-clipboard`            | copy math results                     |
| `curl` + `jq`             | fetching wallpapers & weather         |
| `hyprshot`                | screenshot (region mode)              |
| `notify-send` (libnotify) | pomodoro timer notifications          |
| `pactl` (pipewire-pulse)  | per-application audio mixer           |
| `gtk-launch`              | launch apps from notification clicks  |

## installation

```bash
git clone https://github.com/yourname/lazerbar.git ~/.config/quickshell/lazerbar
# install deps from the lists above
qs -c lazerbar  # or add to hyprland exec-once
```

## keybinds

| Key                                                       | Action                    |
| --------------------------------------------------------- | ------------------------- |
| `$mainMod, D, global, quickshell:launcher`                | toggle app launcher       |
| `$mainMod, W, global, quickshell:wallpaperSelectorToggle` | toggle wallpaper selector |

add these to your `hyprland.conf`, 

## screenshot

<img width="1920" height="1080" alt="2026-06-06-141115_hyprshot" src="https://github.com/user-attachments/assets/40edf5cb-1049-42dd-8105-66ba7e78a432" />


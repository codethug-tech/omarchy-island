# Modesty Dynamic Island for Omarchy

A native [Omarchy](https://github.com/basecamp/omarchy) shell plugin port of [Modesty](https://github.com/sandeepbist/Modesty) by Sandeep Bist.

Brings an interactive, morphing **Dynamic Island** status bar to Omarchy (Quickshell + Hyprland), featuring expandable media with live synced lyrics, interactive clock & calendar, control center with rich hardware submenus, and a dedicated settings manager.

---

## ✨ Features

- **Dynamic Island Top Bar:**
  - **Media Pill:** Track metadata, album artwork, real-time animated equalizer (`cava`), and live time-synced scrolling lyrics from LRCLIB. Expands into a full media controller with seek slider, volume, and playback toggles.
  - **Clock & Calendar Pill:** Compact time/date pill with morphing animations that expands into an interactive full-month calendar.
  - **Quick Controls & Status Pill:** Morphing status orb showing network, audio, and battery indicators. Expands into a complete Control Center with dedicated submenus for:
    - 📶 **Wi-Fi** (scan networks, signal strength, connect)
    - 🔵 **Bluetooth** (paired & nearby devices, battery levels)
    - 🔊 **Sound & Audio** (sink switching, volume, mic levels)
    - ☀️ **Display & Brightness** (monitors, gamma, night light)
    - ⚡ **Power & Performance** (power profiles, battery status)
    - 🎙️ **Privacy Indicators** (microphone & camera status)
- **Built-in Settings App:**
  - Dedicated configuration window with controls for UI scaling, bar heights, pill resting/expanded widths, animations, font families, and toggleable modules.
- **File Drag & Drop Target:**
  - Interactive file drop zone on the island for quick transfers and clipboard staging.
- **Omarchy Native Integration:**
  - Registered as a first-class `bar` plugin in `omarchy-shell`.
  - Replaces or runs alongside other bars seamlessly.
  - Retains Omarchy's native `omarchy.lock` and PAM security daemon.

---

## 🚀 Installation on Omarchy

You can install this plugin directly using Omarchy's built-in plugin manager:

```bash
omarchy plugin add <YOUR-GITHUB-REPO-URL> --enable --yes
omarchy restart shell
```

### Manual Installation

Alternatively, clone directly into your Omarchy plugins folder:

```bash
git clone <YOUR-GITHUB-REPO-URL> ~/.config/omarchy/plugins/sandeepbist.modesty-island
omarchy shell rescanPlugins
omarchy plugin enable sandeepbist.modesty-island
omarchy restart shell
```

---

## 📦 Recommended Dependencies

The plugin works out of the box with standard Omarchy dependencies. For audio visualizer bars, install `cava`:

```bash
omarchy pkg add cava
```

---

## 🛠️ Usage & Controls

- **Left Pill (Media):**
  - Click to open the full media control deck.
  - Live synced lyrics will automatically stream for supported tracks (Spotify and MPRIS players).
- **Center Pill (Clock):**
  - Click to expand the interactive monthly calendar.
- **Right Pill (Controls):**
  - Click to open Quick Settings and system status submenus.
- **Settings:**
  - Open the Modesty Settings window from the island footer or by running:
    ```bash
    quickshell ipc -p /usr/share/omarchy/shell call island toggle settings
    ```

---

## 📜 Credits & License

- Original design and codebase by [Sandeep Bist](https://github.com/sandeepbist/Modesty).
- Ported for **Omarchy Linux** with native shell IPC and Quickshell host facades.
- Licensed under the **GNU General Public License v3.0** (see [LICENSE](LICENSE)).

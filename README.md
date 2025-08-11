# Mark on Double-Click (Evolution EPlugin)
![Platform: Linux](https://img.shields.io/badge/platform-linux-lightgrey)
![Client: Evolution](https://img.shields.io/badge/client-evolution-blue)


**A plugin for GNOME Evolution (Linux).**

**Version:** 4.5  
**Author:** craigh@funktion.net  
**Summary:** Keeps messages **Unread** in the preview pane and marks them **Read** when opened in their own window (double‑click).

## Compatibility
- Tested on **Ubuntu 24.04 (Noble)** with **Evolution 3.52.x** (system package).
- Works with **system Evolution**. **Flatpak Evolution is not supported** (sandbox cannot load system plugins).

## Install (one-liner)
```bash
# From inside this folder:
bash scripts/install.sh
```
The script will:
- auto-detect Evolution’s plugin directory,
- build the plugin with `cc` using `pkg-config` flags,
- install the `.so` and `.eplug` into the correct folder,
- restart Evolution (best effort).

## Uninstall
```bash
bash scripts/uninstall.sh
```

## Build from source (CMake)
```bash
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..
cmake --build . -j
sudo cmake --install .
```

## Distro prerequisites
- **Debian/Ubuntu:**
  ```bash
  sudo apt install build-essential pkg-config cmake evolution-dev \
       libgtk-3-dev libglib2.0-dev camel-1.2 unzip
  ```
- **Fedora/RHEL:**
  ```bash
  sudo dnf install gcc gcc-c++ make pkgconf-pkg-config cmake \
       evolution-devel gtk3-devel glib2-devel libcamel-devel unzip
  ```
- **Arch/Manjaro:**
  ```bash
  sudo pacman -Sy --needed base-devel pkgconf cmake evolution gtk3 glib2 unzip
  ```

## Verify it loaded
Run Evolution from a terminal:
```bash
G_MESSAGES_DEBUG=all evolution
```
Look for:
```
[Mark on Double-Click] Emission hook installed.
```

## Known limitations
- Not visible/usable with **Flatpak Evolution**.
- The plugin has no configuration UI (by design). Enable or disable it in **Edit → Preferences → Plugins**.

## License
MIT — see `LICENSE`.

## Changelog
- **4.5**: Owner-only UI; simplified behavior; cross-distro installer; packaging skeleton.
- See `CHANGELOG.md` for previous history.

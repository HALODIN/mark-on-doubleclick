#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/mark_on_doubleclick_install.log"
exec > >(tee -a "$LOG") 2>&1

echo "== Mark on Double-Click v4.5 installer =="

detect_plugin_dir() {
  local p
  p="$(pkg-config --variable=plugindir evolution-mail-3.0 2>/dev/null || true)"
  if [[ -n "${p:-}" && -d "$p" ]]; then echo "$p"; return 0; fi

  if command -v dpkg >/dev/null 2>&1; then
    p="$(dpkg -L evolution 2>/dev/null | awk '/\/evolution\/plugins\/.*\.so$/ {print; exit}' | xargs -r dirname)"
    if [[ -n "${p:-}" && -d "$p" ]]; then echo "$p"; return 0; fi
  fi

  if command -v rpm >/dev/null 2>&1; then
    p="$(rpm -ql evolution 2>/dev/null | awk '/\/evolution\/plugins\/.*\.so$/ {print; exit}' | xargs -r dirname)"
    if [[ -n "${p:-}" && -d "$p" ]]; then echo "$p"; return 0; fi
  fi

  for c in \
    /usr/lib/evolution/plugins \
    /usr/lib64/evolution/plugins \
    /usr/lib/x86_64-linux-gnu/evolution/plugins \
    /usr/lib/aarch64-linux-gnu/evolution/plugins
  do
    if [[ -d "$c" ]]; then echo "$c"; return 0; fi
  done

  # Fallback
  echo "/usr/lib/evolution/plugins"
}

PLUGINDIR="$(detect_plugin_dir)"
echo "-- Using plugin dir: $PLUGINDIR"

# Prereqs (best-effort per distro)
if command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y build-essential pkg-config cmake \
    evolution-dev libgtk-3-dev libglib2.0-dev unzip camel-1.2 || true
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y gcc gcc-c++ make pkgconf-pkg-config cmake \
    evolution-devel gtk3-devel glib2-devel libcamel-devel unzip || true
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy --needed --noconfirm base-devel pkgconf cmake \
    evolution webkit2gtk gtk3 glib2 unzip || true
fi

# Build in a temp dir
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp -R src data CMakeLists.txt "$WORK/"
cd "$WORK"

# Build with cc (fast path)
CFLAGS="$(pkg-config --cflags evolution-mail-3.0 gtk+-3.0 glib-2.0 gobject-2.0 gmodule-2.0 camel-1.2 2>/dev/null || true)"
LIBS="$(pkg-config --libs   gtk+-3.0 glib-2.0 gobject-2.0 gmodule-2.0 2>/dev/null || true)"
if [[ -z "$CFLAGS" || -z "$LIBS" ]]; then
  echo "!! pkg-config flags not found. Is system Evolution (non-Flatpak) installed?"
  exit 1
fi

cc -fPIC -shared src/mark_on_doubleclick_eplugin.c -o liborg-gnome-mark-on-doubleclick.so $CFLAGS $LIBS

# Generate .eplug with correct path
sed -e "s|@PLUGINDIR@|$PLUGINDIR|g" -e 's|@SOEXT@|.so|g' \
  data/org-gnome-mark-on-doubleclick.eplug.in > org-gnome-mark-on-doubleclick.eplug

# Install
sudo install -Dm755 liborg-gnome-mark-on-doubleclick.so "$PLUGINDIR/liborg-gnome-mark-on-doubleclick.so"
sudo install -Dm644 org-gnome-mark-on-doubleclick.eplug "$PLUGINDIR/org-gnome-mark-on-doubleclick.eplug"

# Restart Evolution (best effort)
evolution --force-shutdown >/dev/null 2>&1 || true
echo "Installed to $PLUGINDIR"
echo "Launch Evolution to use the plugin."

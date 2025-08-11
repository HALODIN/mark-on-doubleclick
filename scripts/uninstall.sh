#!/usr/bin/env bash
set -euo pipefail
detect_plugin_dirs() {
  # search common locations
  for d in \
    "$(pkg-config --variable=plugindir evolution-mail-3.0 2>/dev/null || true)" \
    /usr/lib/evolution/plugins \
    /usr/lib64/evolution/plugins \
    /usr/lib/x86_64-linux-gnu/evolution/plugins \
    /usr/lib/aarch64-linux-gnu/evolution/plugins
  do
    [[ -n "$d" && -d "$d" ]] && echo "$d"
  done
}

for d in $(detect_plugin_dirs); do
  if [[ -f "$d/liborg-gnome-mark-on-doubleclick.so" ]]; then
    echo "Removing $d/liborg-gnome-mark-on-doubleclick.so"
    sudo rm -f "$d/liborg-gnome-mark-on-doubleclick.so"
  fi
  if [[ -f "$d/org-gnome-mark-on-doubleclick.eplug" ]]; then
    echo "Removing $d/org-gnome-mark-on-doubleclick.eplug"
    sudo rm -f "$d/org-gnome-mark-on-doubleclick.eplug"
  fi
done

evolution --force-shutdown >/dev/null 2>&1 || true
echo "Uninstalled."

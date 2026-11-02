#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.7.2"
GODOT_SHA256="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
TEMPLATES_SHA256="f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"
CACHE_DIR="${HOME}/.cache/godot-web"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
mkdir -p "$CACHE_DIR" "$TEMPLATE_DIR" build/web

if ! command -v git-lfs >/dev/null 2>&1; then
  echo "git-lfs is required to fetch the game's original binary assets." >&2
  exit 1
fi
git lfs install --local
git lfs pull
git lfs checkout
git lfs fsck

# Confirm that Git LFS hydrated this voice clip as real Ogg data, not a pointer.
VOICE_CLIP="assets/audio/voice/fighters/valka_special_1.ogg"
if [[ "$(head -c 4 "$VOICE_CLIP")" != "OggS" ]]; then
  echo "Git LFS did not hydrate $VOICE_CLIP as an Ogg file." >&2
  exit 1
fi
echo "Verified original voice clip: $(stat -c '%s bytes' "$VOICE_CLIP")"

ENGINE_ZIP="$CACHE_DIR/godot.zip"
TEMPLATES_TPZ="$CACHE_DIR/templates.tpz"
if [[ ! -f "$ENGINE_ZIP" ]]; then
  curl -fL --retry 3 "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o "$ENGINE_ZIP"
fi
if [[ ! -f "$TEMPLATES_TPZ" ]]; then
  curl -fL --retry 3 "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$TEMPLATES_TPZ"
fi
echo "$GODOT_SHA256  $ENGINE_ZIP" | sha256sum -c -
echo "$TEMPLATES_SHA256  $TEMPLATES_TPZ" | sha256sum -c -

unzip -oq "$ENGINE_ZIP" -d "$CACHE_DIR/engine"
GODOT_BIN="$CACHE_DIR/engine/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
chmod +x "$GODOT_BIN"

WEB_TEMPLATE="$(unzip -Z1 "$TEMPLATES_TPZ" | grep -E '(^|/)web_nothreads_release\.zip$' | head -n 1)"
if [[ -z "$WEB_TEMPLATE" ]]; then
  echo "Could not find Godot's single-threaded Web export template." >&2
  exit 1
fi
unzip -p "$TEMPLATES_TPZ" "$WEB_TEMPLATE" > "$TEMPLATE_DIR/web_nothreads_release.zip"

"$GODOT_BIN" --headless --editor --path . --import
"$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
test -s build/web/index.html
find build/web -maxdepth 1 -type f -printf '%f %s bytes\n'

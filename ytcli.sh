#!/usr/bin/env bash
#
# ytcli — download YouTube videos on a Mac and send them to an Android phone.
#
# Usage:
#   ytcli.sh [--share | --open] [--clipboard]
#
#   --share       push the downloaded folder to the phone via adb (default)
#   --open        reveal the downloaded folder in Finder instead
#   --clipboard   read links from the clipboard instead of opening an editor
#
set -euo pipefail

# --- configuration ----------------------------------------------------------

LINKS_FILE="${TMPDIR:-/tmp}/ytcli-links.txt"
DOWNLOAD_ROOT="$HOME/Downloads"
REMOTE_DIR="/sdcard/Download"
MAX_HEIGHT=1080

# --- argument parsing --------------------------------------------------------

destination="share"   # default
use_clipboard=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --share)     destination="share" ;;
    --open)      destination="open" ;;
    --clipboard) use_clipboard=true ;;
    -h|--help)
      sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ytcli: unknown option '$1'" >&2
      exit 2
      ;;
  esac
  shift
done

# --- dependency checks -------------------------------------------------------

command -v yt-dlp >/dev/null 2>&1 || { echo "ytcli: yt-dlp is not installed (brew install yt-dlp)" >&2; exit 1; }
if [[ "$destination" == "share" ]]; then
  command -v adb >/dev/null 2>&1 || { echo "ytcli: adb is not installed (brew install --cask android-platform-tools)" >&2; exit 1; }
fi

# --- keep yt-dlp up to date --------------------------------------------------

echo "==> Checking for yt-dlp updates..."
if command -v brew >/dev/null 2>&1; then
  brew upgrade yt-dlp || true   # no-op if already current; don't abort the run on a hiccup
else
  echo "    brew not found; skipping update check."
fi

# --- collect links -----------------------------------------------------------

links=()

if $use_clipboard; then
  echo "==> Reading links from the clipboard..."
  while IFS= read -r line; do
    links+=("$line")
  done < <(pbpaste)
else
  touch "$LINKS_FILE"
  open -e "$LINKS_FILE"   # open in TextEdit
  echo "==> Editing $LINKS_FILE in TextEdit."
  echo "    Paste one link per line, save the file, then come back here."
  read -r -p "    Press Enter once the links are saved... " _
  while IFS= read -r line; do
    links+=("$line")
  done < "$LINKS_FILE"
fi

# drop blank lines and #-comments, trim surrounding whitespace
cleaned=()
for line in "${links[@]}"; do
  line="${line#"${line%%[![:space:]]*}"}"   # ltrim
  line="${line%"${line##*[![:space:]]}"}"   # rtrim
  [[ -z "$line" || "$line" == \#* ]] && continue
  cleaned+=("$line")
done

if [[ ${#cleaned[@]} -eq 0 ]]; then
  echo "ytcli: no links to download." >&2
  exit 1
fi

echo "==> ${#cleaned[@]} link(s) to download."

# --- download ----------------------------------------------------------------

stamp="$(date +%Y%m%d-%H%M%S)"
target_dir="$DOWNLOAD_ROOT/$stamp"
mkdir -p "$target_dir"

echo "==> Downloading into $target_dir"
yt-dlp \
  -f "bv*[height<=$MAX_HEIGHT]+ba/b[height<=$MAX_HEIGHT]" \
  --merge-output-format mp4 \
  -o "$target_dir/%(title)s.%(ext)s" \
  "${cleaned[@]}"

# --- deliver -----------------------------------------------------------------

if [[ "$destination" == "open" ]]; then
  echo "==> Opening $target_dir in Finder."
  open "$target_dir"
else
  echo "==> Pushing to the phone..."
  if [[ "$(adb get-state 2>/dev/null)" != "device" ]]; then
    echo "ytcli: no phone connected via adb. Plug it in (USB debugging on) and retry." >&2
    echo "       The download is safe at: $target_dir" >&2
    exit 1
  fi
  adb push "$target_dir" "$REMOTE_DIR/"
  echo "==> Done. Files are in $REMOTE_DIR/$stamp on the phone."
fi

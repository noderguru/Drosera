#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
SERVICE_NAME="drosera"
INSTALL_DIR="/root/.drosera/bin"
TMP_DIR="/tmp/drosera-update"
GITHUB_API_URL="https://api.github.com/repos/drosera-network/releases/releases/latest"

GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"
echo_green() { echo -e "${GREEN}$1${RESET}"; }
echo_red()   { echo -e "${RED}$1${RESET}"; }

# === STEP 1: Get latest version from GitHub ===
echo_green "🔎 Checking latest version on GitHub..."
LATEST_VERSION=$(curl -s "$GITHUB_API_URL" | grep -oP '"tag_name":\s*"v\K[0-9.]+' || true)

if [[ -z "$LATEST_VERSION" ]]; then
  echo_red "❌ Failed to fetch latest version from GitHub."
  exit 1
fi

echo_green "🆕 Latest available version: v$LATEST_VERSION"

# === BINARIES TO UPDATE ===
declare -A BINARIES=(
  ["drosera"]="drosera-v${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
  ["drosera-operator"]="drosera-operator-v${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
)

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

ANY_UPDATED=false

# === LOOP: Update each binary if needed ===
for bin in "${!BINARIES[@]}"; do
  BIN_PATH="$INSTALL_DIR/$bin"
  ARCHIVE_NAME="${BINARIES[$bin]}"
  echo_green "\n📦 Checking binary: $bin"

  if [[ -x "$BIN_PATH" ]]; then
    CURRENT_VERSION=$("$BIN_PATH" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo_green "   Installed version: v$CURRENT_VERSION"
  else
    echo_red "   $bin not found, assuming version: 0.0.0"
    CURRENT_VERSION="0.0.0"
  fi

  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo_green "   ✅ $bin is already up to date."
    continue
  fi

  echo_green "   ⬇️  Downloading $ARCHIVE_NAME..."
  wget -q --show-progress "https://github.com/drosera-network/releases/releases/download/v${LATEST_VERSION}/${ARCHIVE_NAME}" -O "$ARCHIVE_NAME"

  echo_green "   📦 Extracting archive..."
  tar -xvf "$ARCHIVE_NAME"

  echo_green "   🔁 Replacing old $bin binary..."
  cp "$bin" "$BIN_PATH"
  chmod +x "$BIN_PATH"

  NEW_VERSION=$("$BIN_PATH" --version || echo "failed")
  echo_green "   ✅ Updated $bin to version: $NEW_VERSION"
  ANY_UPDATED=true
done

# === SERVICE RESTART ===
if [[ "$ANY_UPDATED" = true ]]; then
  echo_green "\n🛑 Stopping $SERVICE_NAME..."
  sudo systemctl stop "$SERVICE_NAME"

  echo_green "🚀 Starting $SERVICE_NAME..."
  sudo systemctl start "$SERVICE_NAME"
else
  echo_green "\n🟢 No updates applied. Service restart not needed."
fi

# === LOG FOLLOW ===
sleep 2
echo_green "\n📡 Streaming logs for $SERVICE_NAME (press Ctrl+C to stop)..."
sudo journalctl -u "$SERVICE_NAME" -f -n 20

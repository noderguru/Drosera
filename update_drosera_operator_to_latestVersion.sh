#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
SERVICE_NAME="drosera"  # systemd service name
INSTALL_DIR="/root/.drosera/bin"
BIN_PATH="$INSTALL_DIR/drosera-operator"
TMP_DIR="/tmp/drosera-operator-update"
GITHUB_API_URL="https://api.github.com/repos/drosera-network/releases/releases/latest"

# === COLORS ===
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"
echo_green() { echo -e "${GREEN}$1${RESET}"; }
echo_red()   { echo -e "${RED}$1${RESET}"; }

# === STEP 1: Detect current version ===
if [[ -x "$BIN_PATH" ]]; then
  CURRENT_VERSION=$("$BIN_PATH" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  echo_green "📦 Current installed version: v$CURRENT_VERSION"
else
  echo_red "drosera-operator binary not found, assuming version: none"
  CURRENT_VERSION="0.0.0"
fi

# === STEP 2: Get latest version from GitHub ===
echo_green "🔎 Checking latest version on GitHub..."
LATEST_VERSION=$(curl -s "$GITHUB_API_URL" | grep -oP '"tag_name":\s*"v\K[0-9.]+')

if [[ -z "$LATEST_VERSION" ]]; then
  echo_red "❌ Failed to fetch latest version from GitHub."
  exit 1
fi

echo_green "🆕 Latest available version: v$LATEST_VERSION"

# === STEP 3: Compare versions ===
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
  echo_green "✅ drosera-operator is already up to date."
  exit 0
fi

# === STEP 4: Build download URL ===
ARCHIVE_NAME="drosera-operator-v${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
DOWNLOAD_URL="https://github.com/drosera-network/releases/releases/download/v${LATEST_VERSION}/${ARCHIVE_NAME}"

echo_green "⬇️  New version available: downloading v$LATEST_VERSION..."

# === STEP 5: Stop service ===
echo_green "🛑 Stopping $SERVICE_NAME..."
sudo systemctl stop "$SERVICE_NAME" || echo_red "Service $SERVICE_NAME not running or not found."

# === STEP 6: Download & extract ===
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

wget -q --show-progress "$DOWNLOAD_URL" -O "$ARCHIVE_NAME"
tar -xvf "$ARCHIVE_NAME"

# === STEP 7: Replace binary ===
echo_green "⚙️ Installing new version..."
cp drosera-operator "$BIN_PATH"
chmod +x "$BIN_PATH"

# === STEP 8: Start service ===
echo_green "🚀 Starting $SERVICE_NAME..."
sudo systemctl start "$SERVICE_NAME"

# === STEP 9: Show version ===
echo_green "✅ Version after update:"
"$BIN_PATH" --version || echo_red "Could not retrieve version"

# === STEP 10: Follow logs ===
sleep 2
echo_green "📡 Streaming live logs for $SERVICE_NAME (press Ctrl+C to exit)..."
sudo journalctl -u "$SERVICE_NAME" -f -n 20

#!/bin/bash

# Change to the directory where the script is located
cd "$(dirname "$0")" || exit 1

echo "========================================================"
echo "Antigravity IDE Patch Installer (Linux/Debian)"
echo "========================================================"
echo

# If system Node.js is already installed, use it directly
if command -v node >/dev/null 2>&1; then
    echo "Found system Node.js ($(node -v)). Running patch directly..."
    echo
    node applyAutoRetryContinueAllowPatch.js "$@"
    EXIT_CODE=$?
    echo
    echo "========================================================"
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Patch process finished successfully!"
    else
        echo "Patch process finished with errors (Code $EXIT_CODE)."
    fi
    echo "========================================================"
    read -p "Press [Enter] to exit..."
    exit $EXIT_CODE
fi

echo "This script will temporarily download Node.js to apply"
echo "the patch without modifying your system installations."
echo

TMP_DIR="$(pwd)/.tmp_node"
echo "Creating temporary directory at $TMP_DIR..."
mkdir -p "$TMP_DIR"

# Determine architecture (x86_64 vs arm64/aarch64)
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    NODE_ARCH="linux-arm64"
else
    NODE_ARCH="linux-x64"
fi

echo "[1/3] Fetching latest Node.js release info for $NODE_ARCH..."
# Fetch the filename of the latest Linux binary tarball
LATEST_TARBALL=$(curl -s https://nodejs.org/dist/latest/SHASUMS256.txt | grep "$NODE_ARCH.tar.gz" | awk '{print $2}')

if [ -z "$LATEST_TARBALL" ]; then
    echo
    echo "ERROR: Could not determine the latest Node.js version. Please check your internet connection."
    echo "Cleaning up..."
    rm -rf "$TMP_DIR"
    read -p "Press [Enter] to exit..."
    exit 1
fi

NODE_URL="https://nodejs.org/dist/latest/$LATEST_TARBALL"
TAR_FILE="$TMP_DIR/node_latest.tar.gz"

echo "Downloading $LATEST_TARBALL..."
echo "Source URL: $NODE_URL"
echo "Destination: $TAR_FILE"
curl -# -L -o "$TAR_FILE" "$NODE_URL"

if [ ! -f "$TAR_FILE" ]; then
    echo
    echo "ERROR: Failed to download Node.js."
    echo "Cleaning up..."
    rm -rf "$TMP_DIR"
    read -p "Press [Enter] to exit..."
    exit 1
fi

echo "Extracting Node.js to $TMP_DIR..."
tar -xzf "$TAR_FILE" -C "$TMP_DIR"

# Find the node executable inside the extracted folder
NODE_EXE=$(find "$TMP_DIR" -path "*/bin/node" -type f | head -n 1)

if [ -z "$NODE_EXE" ] || [ ! -f "$NODE_EXE" ]; then
    echo
    echo "ERROR: Failed to extract or find the Node.js executable."
    echo "Cleaning up..."
    rm -rf "$TMP_DIR"
    read -p "Press [Enter] to exit..."
    exit 1
fi

# Ensure it is executable
chmod +x "$NODE_EXE"

echo
echo "[2/3] Applying the patch..."
echo "Executing script: applyAutoRetryContinueAllowPatch.js using portable Node.js..."
echo
"$NODE_EXE" applyAutoRetryContinueAllowPatch.js "$@"
EXIT_CODE=$?

echo
echo "[3/3] Cleaning up temporary files..."
echo "Removing directory $TMP_DIR..."
rm -rf "$TMP_DIR"

echo
echo "========================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "Patch process finished successfully!"
else
    echo "Patch process finished with errors (Code $EXIT_CODE)."
fi
echo "========================================================"

# Keep terminal open if run by double-clicking in a file manager
read -p "Press [Enter] to exit..."

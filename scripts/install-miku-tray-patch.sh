#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

echo "Creating the tray patch script..."
cat << 'INNER_EOF' > /usr/local/bin/patch-antigravity-tray.sh
#!/bin/bash
set -eo pipefail

MAIN_USER=$(awk -F':' '{ if ($3 >= 1000 && $3 < 65534) { print $1; exit } }' /etc/passwd)
MAIN_USER_HOME=$(eval echo "~$MAIN_USER")

ASAR="/opt/Antigravity/resources/app.asar"
SVG_FILE="$MAIN_USER_HOME/.local/share/icons/YAMIS-enlarged/apps/scalable/antigravity.svg"

if [ ! -f "$ASAR" ]; then
    echo "Warning: Antigravity ASAR not found at $ASAR. Skipping tray patch."
    exit 0
fi

if [ ! -f "$SVG_FILE" ]; then
    echo "Warning: SVG source file not found at $SVG_FILE. Skipping tray patch."
    exit 0
fi

# Create a secure temp directory owned by the user
TMP_PARENT=$(mktemp -d -t antigravity-patch-XXXXXX)
chown "$MAIN_USER":"$MAIN_USER" "$TMP_PARENT"
chmod 700 "$TMP_PARENT"

TMP_DIR="$TMP_PARENT/extracted"
TMP_ASAR="$TMP_PARENT/app.asar.patched"

cleanup() {
    rm -rf "$TMP_PARENT"
}
trap cleanup EXIT

# Run asar extraction as the user
sudo -u "$MAIN_USER" npx -y asar extract "$ASAR" "$TMP_DIR"

# Modify files
rsvg-convert -w 16 -h 16 "$SVG_FILE" -o "$TMP_DIR/trayTemplate.png"
rsvg-convert -w 32 -h 32 "$SVG_FILE" -o "$TMP_DIR/trayTemplate@2x.png"
rsvg-convert -w 48 -h 48 "$SVG_FILE" -o "$TMP_DIR/icon.png"

# Repack as the user
sudo -u "$MAIN_USER" npx -y asar pack "$TMP_DIR" "$TMP_ASAR"

# Overwrite system ASAR
mv "$TMP_ASAR" "$ASAR"
INNER_EOF

chmod +x /usr/local/bin/patch-antigravity-tray.sh

echo "Creating the pacman hook for automatic patching on updates..."
mkdir -p /etc/pacman.d/hooks
cat << 'INNER_EOF' > /etc/pacman.d/hooks/antigravity-tray-patch.hook
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = antigravity
Target = antigravity-bin

[Action]
Description = Patching Antigravity tray icon to use the monochrome logo...
When = PostTransaction
Exec = /usr/local/bin/patch-antigravity-tray.sh
INNER_EOF

echo "Running the patcher for the first time..."
/usr/local/bin/patch-antigravity-tray.sh

echo "Done! The tray icon is permanently patched!"

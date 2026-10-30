#!/bin/zsh
set -eu
cd "$(dirname "$0")"
zsh build.sh
mkdir -p dist
# Stage outside synced Documents folders, which can add Finder metadata that
# invalidates strict signature verification. Never include extended attributes.
stage=$(mktemp -d "${TMPDIR:-/tmp}/orbit-installer.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto --norsrc --noextattr Orbit.app "$stage/Orbit.app"
xattr -cr "$stage/Orbit.app"
codesign --force --deep --sign - "$stage/Orbit.app"
codesign --verify --deep --strict "$stage/Orbit.app"
ln -s /Applications "$stage/Applications"
cp INSTALL.txt "$stage/INSTALL.txt"
cp LICENSE "$stage/LICENSE.txt"
hdiutil create -volname "Orbit" -srcfolder "$stage" -ov -format UDZO dist/Orbit-1.1.0-universal.dmg
ditto --norsrc --noextattr -c -k --keepParent "$stage/Orbit.app" dist/Orbit-1.1.0-universal.zip
shasum -a 256 dist/Orbit-1.1.0-universal.dmg dist/Orbit-1.1.0-universal.zip > dist/SHA256SUMS.txt

#!/bin/zsh
set -eu
cd "$(dirname "$0")"
mkdir -p dist build
if [[ -n "${DMGBUILD:-}" ]]; then
    dmgbuild_tool="$DMGBUILD"
else
    if [[ ! -x build/installer-tools/bin/dmgbuild ]]; then
        python3 -m venv build/installer-tools
        build/installer-tools/bin/python -m pip install -r Packaging/requirements.txt
    fi
    dmgbuild_tool="$PWD/build/installer-tools/bin/dmgbuild"
fi
packaging_python="$(dirname "$dmgbuild_tool")/python"
zsh build.sh
# Stage outside synced Documents folders, which can add Finder metadata that
# invalidates strict signature verification. Never include extended attributes.
stage=$(mktemp -d "${TMPDIR:-/tmp}/orbit-installer.XXXXXX")
mounted=0
cleanup() {
    if [[ "$mounted" == 1 ]]; then hdiutil detach -quiet "$stage/mount" || true; fi
    rm -rf "$stage"
}
trap cleanup EXIT
ditto --norsrc --noextattr Orbit.app "$stage/Orbit.app"
xattr -cr "$stage/Orbit.app"
codesign --force --deep --sign - "$stage/Orbit.app"
codesign --verify --deep --strict "$stage/Orbit.app"
xcrun swift -module-cache-path "${TMPDIR:-/tmp}/orbit-swift-cache" Packaging/render_installer.swift "$stage/artwork" Assets/Orbit.png
"$dmgbuild_tool" -s Packaging/dmg_settings.py -D "app=$stage/Orbit.app" -D "icon=$PWD/Assets/Orbit.icns" -D "background=$stage/artwork/background.tiff" "Orbit 1.2.1" "$stage/Orbit.dmg"
hdiutil verify -quiet "$stage/Orbit.dmg"
mkdir "$stage/mount"
hdiutil attach -quiet -readonly -nobrowse -mountpoint "$stage/mount" "$stage/Orbit.dmg"
mounted=1
"$packaging_python" Packaging/verify_installer.py "$stage/mount"
hdiutil detach -quiet "$stage/mount"
mounted=0
cp "$stage/Orbit.dmg" dist/Orbit-1.2.1-universal.dmg
mkdir -p Assets/Installer
cp "$stage/artwork/installer-preview.png" Assets/Installer/installer-preview.png
cp "$stage/artwork/background.tiff" Assets/Installer/background.tiff
ditto --norsrc --noextattr -c -k --keepParent "$stage/Orbit.app" dist/Orbit-1.2.1-universal.zip
(cd dist && shasum -a 256 Orbit-1.2.1-universal.dmg Orbit-1.2.1-universal.zip > SHA256SUMS.txt)

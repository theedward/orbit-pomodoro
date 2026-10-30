#!/bin/zsh
set -eu
cd "$(dirname "$0")"
zsh build.sh
mkdir -p build/installer dist
ditto Orbit.app build/installer/Orbit.app
if [[ ! -L build/installer/Applications ]]; then ln -s /Applications build/installer/Applications; fi
cp INSTALL.txt build/installer/INSTALL.txt
cp LICENSE build/installer/LICENSE.txt
hdiutil create -volname "Orbit" -srcfolder build/installer -ov -format UDZO dist/Orbit-1.0.0-universal.dmg
ditto -c -k --keepParent Orbit.app dist/Orbit-1.0.0-universal.zip
shasum -a 256 dist/Orbit-1.0.0-universal.dmg dist/Orbit-1.0.0-universal.zip > dist/SHA256SUMS.txt

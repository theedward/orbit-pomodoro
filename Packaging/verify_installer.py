"""Verify the actual mounted image, including Finder presentation metadata."""
import os
from pathlib import Path
import plistlib
import subprocess
import sys
from ds_store import DSStore

mount = Path(sys.argv[1])
app = mount / 'Orbit.app'
assert app.is_dir(), 'App is missing'
assert os.readlink(mount / 'Applications') == '/Applications'
with DSStore.open(str(mount / '.DS_Store'), 'r') as store:
    assert store['Orbit.app']['Iloc'] == (210, 278)
    assert store['Applications']['Iloc'] == (510, 278)
    assert store['.']['icvp']['backgroundType'] == 2
    assert store['.']['icvp']['iconSize'] == 104
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
architectures = set(subprocess.check_output(['lipo', '-archs', str(app / 'Contents/MacOS/Orbit')], text=True).split())
assert architectures == {'arm64', 'x86_64'}
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
assert info['CFBundleShortVersionString'] == '1.2.1'
assert (app / 'Contents/Resources/Orbit.icns').stat().st_size > 0
assert (app / 'Contents/Resources/LICENSE.txt').read_text().startswith('MIT License')
print('Verified mounted installer: signature, architectures, app icon, license, background, icon positions, and Applications shortcut.')

"""Fail before building if the launcher class or Firebase app ID drifts."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = (root / 'android/app/build.gradle.kts').read_text()
application_id = re.search(r'applicationId\s*=\s*"([^"]+)"', app).group(1)
namespace = re.search(r'namespace\s*=\s*"([^"]+)"', app).group(1)
assert application_id == namespace, 'Android namespace and application ID differ'
activity = root / 'android/app/src/main/kotlin' / Path(*namespace.split('.')) / 'MainActivity.kt'
assert activity.is_file(), f'Missing launcher activity: {activity}'
assert f'package {namespace}' in activity.read_text(), 'Kotlin activity package differs'
manifest = (root / 'android/app/src/main/AndroidManifest.xml').read_text()
assert f'android:name="{namespace}.MainActivity"' in manifest, 'Use the explicit launcher class'
assert 'android.permission.INTERNET' in manifest, 'Release build needs internet permission'
config = json.loads((root / 'android/app/google-services.json').read_text())
assert application_id in [c['client_info']['android_client_info']['package_name'] for c in config['client']]
print(f'Android launcher and Firebase package verified: {application_id}')

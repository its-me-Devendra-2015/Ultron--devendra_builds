from pathlib import Path
import plistlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
IOS = ROOT / "ios" / "Runner" / "Info.plist"

if not ANDROID.exists() or not IOS.exists():
    raise SystemExit("Run 'flutter create --platforms=android,ios .' from mobile/ before this script.")

ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
ns = "{http://schemas.android.com/apk/res/android}"
tree = ET.parse(ANDROID)
manifest = tree.getroot()
existing = {node.get(ns + "name") for node in manifest.findall("uses-permission")}
for permission in (
    "android.permission.INTERNET",
    "android.permission.RECORD_AUDIO",
    "android.permission.CAMERA",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.CHANGE_NETWORK_STATE",
    "android.permission.MODIFY_AUDIO_SETTINGS",
):
    if permission not in existing:
        ET.SubElement(manifest, "uses-permission", {ns + "name": permission})
tree.write(ANDROID, encoding="utf-8", xml_declaration=True)

with IOS.open("rb") as stream:
    info = plistlib.load(stream)
info["NSMicrophoneUsageDescription"] = "ULTRON uses the microphone for live voice conversations."
info["NSCameraUsageDescription"] = "ULTRON uses the camera when you enable video during a call."
with IOS.open("wb") as stream:
    plistlib.dump(info, stream)
print("Configured Android and iOS microphone/camera permission descriptions.")

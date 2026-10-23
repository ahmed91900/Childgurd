"""Check the built universal APK, including its actual ELF architectures and signature."""
import argparse
import os
from pathlib import Path
import re
import struct
import subprocess
from zipfile import ZipFile

EXPECTED = {"armeabi-v7a": (1, 40), "arm64-v8a": (2, 183), "x86_64": (2, 62)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    args = parser.parse_args()
    with ZipFile(args.apk) as archive:
        if archive.testzip() is not None:
            raise SystemExit("APK ZIP integrity check failed")
        actual = {
            name.split("/")[1] for name in archive.namelist()
            if name.startswith("lib/") and name.endswith("/libflutter.so")
        }
        if actual != set(EXPECTED):
            raise SystemExit(f"Expected universal Flutter ABIs {set(EXPECTED)}, found {actual}")
        for abi, (elf_class, machine) in EXPECTED.items():
            with archive.open(f"lib/{abi}/libflutter.so") as engine:
                header = engine.read(20)
            if (header[:4] != b"\x7fELF" or header[4] != elf_class or header[5] != 1
                    or struct.unpack_from("<H", header, 18)[0] != machine):
                raise SystemExit(f"Invalid ELF architecture for {abi}")
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not sdk:
        raise SystemExit("Set ANDROID_HOME or ANDROID_SDK_ROOT to verify SDK metadata/signature")
    build_tools = Path(sdk) / "build-tools" / "35.0.0"
    badging = subprocess.check_output(
        [str(build_tools / "aapt"), "dump", "badging", str(args.apk)], text=True
    )
    manifest = subprocess.check_output(
        [str(build_tools / "aapt"), "dump", "xmltree", str(args.apk), "AndroidManifest.xml"], text=True
    )
    ad_meta = next((block for block in manifest.split("E: meta-data")
                    if "com.google.android.gms.ads.APPLICATION_ID" in block), "")
    if not re.search(r'android:value[^\n]*="ca-app-pub-\d+~\d+"', ad_meta):
        raise SystemExit("Missing/invalid ads SDK application ID, including in ads-disabled builds")
    minimum = re.search(r"^sdkVersion:'(\d+)'", badging, re.MULTILINE)
    if minimum is None or int(minimum[1]) != 24:
        raise SystemExit("Universal beta must retain minimum Android API 24")
    subprocess.run([str(build_tools / "apksigner"), "verify", "--verbose", str(args.apk)], check=True)
    print("Universal APK verified: Android 7.0+; ARM32, ARM64 and x86-64 ELF engines; valid signature.")


if __name__ == "__main__":
    main()

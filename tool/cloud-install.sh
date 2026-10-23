#!/usr/bin/env bash
set -euo pipefail
cd /workspace/Childgurd
source tool/cloud-env.sh
mkdir -p /workspace/tools "$PUB_CACHE" "$XDG_CONFIG_HOME" "$GRADLE_USER_HOME" "$ANDROID_USER_HOME"

if [[ ! -x "$JAVA_HOME/bin/javac" ]]; then
  jdk_archive=$(mktemp /tmp/kidsafe-jdk.XXXXXX.tar.gz)
  curl --fail --location --silent --show-error \
    'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz' \
    --output "$jdk_archive"
  printf '%s  %s\n' ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94 "$jdk_archive" | sha256sum --check
  tar -xzf "$jdk_archive" -C /workspace/tools
  rm -f "$jdk_archive"
fi
"$JAVA_HOME/bin/javac" -version

flutter_revision=adc901062556672b4138e18a4dc62a4be8f4b3c2
if [[ ! -d /workspace/tools/flutter/.git ]]; then
  git clone --depth 1 --branch 3.35.7 https://github.com/flutter/flutter.git /workspace/tools/flutter
fi
[[ "$(git -C /workspace/tools/flutter rev-parse HEAD)" == "$flutter_revision" ]] || {
  echo 'Unexpected Flutter revision. Preserve it and inspect before replacing.' >&2
  exit 1
}
flutter config --no-analytics --android-sdk "$ANDROID_HOME"
flutter config --jdk-dir "$JAVA_HOME"
flutter --version

if [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
  # Official command-line tools 23.0. SHA-256 was measured only after matching
  # the checksum in Google's HTTPS repository2-3.xml metadata.
  sdk_archive=$(mktemp /tmp/kidsafe-sdk.XXXXXX.zip)
  sdk_extract=$(mktemp -d /tmp/kidsafe-sdk-extract.XXXXXX)
  trap 'rm -f "$sdk_archive"; rm -rf "$sdk_extract"' EXIT
  curl --fail --location --silent --show-error \
    https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip \
    --output "$sdk_archive"
  printf '%s  %s\n' 0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8 "$sdk_archive" | sha256sum --check
  unzip -q "$sdk_archive" -d "$sdk_extract"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  mv "$sdk_extract/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
# This SDK tools release delegates to Google's Android CLI. License review and
# SDK use remain subject to Google's terms; no verification is disabled.
sdkmanager --sdk_root="$ANDROID_HOME" --licenses < /dev/null
sdkmanager --sdk_root="$ANDROID_HOME" \
  'platform-tools' 'platforms;android-36' 'build-tools;35.0.0' \
  'ndk;27.0.12077973' 'cmake;3.22.1'

python3 tool/configure_proxy.py
printf '%s  %s\n' 2db75c40782f5e8ba1fc278a5574bab070adccb2d21ca5a6e5ed840888448046 \
  android/gradle/wrapper/gradle-wrapper.jar | sha256sum --check
flutter pub get --enforce-lockfile
# Package all three supported Android CPU architectures in one APK.
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64

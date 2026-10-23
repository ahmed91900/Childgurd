#!/usr/bin/env bash
# Source this file; do not change HOME or bake proxy credentials into the repo.
export PUB_CACHE=/workspace/.cache/pub
export XDG_CONFIG_HOME=/workspace/.config
export ANDROID_HOME=/workspace/tools/android-sdk
export ANDROID_USER_HOME=/workspace/.android
export GRADLE_USER_HOME=/workspace/.cache/gradle
export JAVA_HOME=/workspace/tools/jdk-21.0.12.1+1
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="/workspace/tools/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

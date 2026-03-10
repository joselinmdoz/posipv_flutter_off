#!/usr/bin/env bash

PROJECT_ROOT="/home/mdoz/proyectos/Android/POSIPV"
export FLUTTER_HOME="$PROJECT_ROOT/.sdk/flutter"
export JAVA_HOME="$PROJECT_ROOT/.sdk/jdk-17"
export ANDROID_SDK_ROOT="/home/mdoz/Android/Sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$JAVA_HOME/bin:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

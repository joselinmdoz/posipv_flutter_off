#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
LOCAL_SDK_DIR="$PROJECT_ROOT/.sdk"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/mdoz/Android/Sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"

if [ -d "$LOCAL_SDK_DIR/flutter" ]; then
  export FLUTTER_HOME="$LOCAL_SDK_DIR/flutter"
fi

if [ -d "$LOCAL_SDK_DIR/jdk-17" ]; then
  export JAVA_HOME="$LOCAL_SDK_DIR/jdk-17"
elif command -v java >/dev/null 2>&1; then
  JAVA_BIN="$(readlink -f "$(command -v java)")"
  export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
fi

if [ -n "${JAVA_HOME:-}" ] && [ ! -d "$JAVA_HOME" ]; then
  echo "Advertencia: JAVA_HOME no es valido: $JAVA_HOME"
  unset JAVA_HOME
fi

if [ -n "${FLUTTER_HOME:-}" ] && [ -d "$FLUTTER_HOME/bin" ]; then
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME/bin" ]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi

if [ -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
  export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
fi

if [ -d "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ]; then
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
fi

echo "Entorno cargado:"
echo "  PROJECT_ROOT=$PROJECT_ROOT"
echo "  JAVA_HOME=${JAVA_HOME:-<no detectado>}"
echo "  FLUTTER_HOME=${FLUTTER_HOME:-<PATH del sistema>}"

#!/usr/bin/env bash

# Fast launch script - skips unnecessary checks for faster startup

set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
	realpath() { [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"; }
	ROOT=$(dirname "$(dirname "$(realpath "$0")")")
else
	ROOT=$(dirname "$(dirname "$(readlink -f $0)")")
	if grep -qi Microsoft /proc/version && type powershell.exe > /dev/null 2>&1; then
		IN_WSL=true
	fi
fi

function code-fast() {
	cd "$ROOT"

	if [[ "$OSTYPE" == "darwin"* ]]; then
		NAME=`node -p "require('./product.json').nameLong"`
		CODE="./.build/electron/$NAME.app/Contents/MacOS/Electron"
	else
		NAME=`node -p "require('./product.json').applicationName"`
		CODE=".build/electron/$NAME"
	fi

	# Skip prelaunch checks for faster startup
	export VSCODE_SKIP_PRELAUNCH=1
	export VSCODE_SKIP_AUTO_MONITOR=1

	# Configuration
	export NODE_ENV=development
	export VSCODE_DEV=1
	export VSCODE_CLI=1
	# Disable verbose logging for faster startup
	# export ELECTRON_ENABLE_STACK_DUMPING=1
	# export ELECTRON_ENABLE_LOGGING=1

	DISABLE_TEST_EXTENSION="--disable-extension=vscode.vscode-api-tests"
	if [[ "$@" == *"--extensionTestsPath"* ]]; then
		DISABLE_TEST_EXTENSION=""
	fi

	# Launch Code directly - skip all checks
	exec "$CODE" . $DISABLE_TEST_EXTENSION "$@"
}

if [ "$IN_WSL" == "true" ] && [ -z "$DISPLAY" ]; then
	code-fast "$@"
elif [ -f /mnt/wslg/versions.txt ]; then
	code-fast --disable-gpu "$@"
elif [ -f /.dockerenv ]; then
	code-fast --disable-dev-shm-usage "$@"
else
	code-fast "$@"
fi

exit $?


#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
app_bundle=${COPILOT_USAGE_APP_BUNDLE:-"$HOME/Applications/Copilot Usage.app"}
app_executable="$app_bundle/Contents/MacOS/copilot-usage"

if [ ! -x "$app_executable" ]; then
	sh "$script_dir/build-app.sh" "$app_bundle"
fi

exec open -a "$app_bundle" --args "$@"

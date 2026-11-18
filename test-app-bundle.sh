#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/copilot-usage-app-test.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM

app_bundle="$temporary_dir/Copilot Usage.app"
sh "$script_dir/build-app.sh" "$app_bundle"

bundle_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_bundle/Contents/Info.plist")
test "$bundle_identifier" = "com.jgarri.copilot-usage"
cli_working_directory=$(/usr/libexec/PlistBuddy -c 'Print :CopilotUsageCLIWorkingDirectory' "$app_bundle/Contents/Info.plist")
expected_working_directory=$script_dir
test "$cli_working_directory" = "$expected_working_directory"
test -x "$app_bundle/Contents/MacOS/copilot-usage"
test -f "$app_bundle/Contents/Resources/usage-percent.sh"
test -f "$app_bundle/Contents/Resources/cli-plan-percent.exp"
codesign --verify --deep --strict "$app_bundle"
designated_requirement=$(codesign -dr - "$app_bundle" 2>&1)
case "$designated_requirement" in
	*'designated => identifier "com.jgarri.copilot-usage"'*) ;;
	*) printf 'Unexpected designated requirement: %s\n' "$designated_requirement" >&2; exit 1 ;;
esac

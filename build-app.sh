#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
project_root=$script_dir
bundle_identifier="com.jgarri.copilot-usage"
app_bundle=${1:-"$HOME/Applications/Copilot Usage.app"}

if [ -e "$app_bundle" ]; then
	existing_identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_bundle/Contents/Info.plist" 2>/dev/null || true)
	if [ "$existing_identifier" != "$bundle_identifier" ]; then
		printf 'Refusing to overwrite an app without bundle identifier %s: %s\n' "$bundle_identifier" "$app_bundle" >&2
		exit 1
	fi
fi

swift build --package-path "$script_dir" --configuration release

binary="$script_dir/.build/release/copilot-usage"
if [ ! -x "$binary" ]; then
	printf 'Build did not produce the expected executable: %s\n' "$binary" >&2
	exit 1
fi

mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cp "$binary" "$app_bundle/Contents/MacOS/copilot-usage"
cp "$script_dir/Resources/Info.plist" "$app_bundle/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CopilotUsageCLIWorkingDirectory string $project_root" "$app_bundle/Contents/Info.plist"
cp "$script_dir/usage-percent.sh" "$app_bundle/Contents/Resources/usage-percent.sh"
cp "$script_dir/cli-plan-percent.exp" "$app_bundle/Contents/Resources/cli-plan-percent.exp"
printf 'designated => identifier "%s"\n' "$bundle_identifier" \
	| codesign --force --deep --sign - --identifier "$bundle_identifier" --requirements - "$app_bundle"
codesign --verify --deep --strict "$app_bundle"
printf 'Installed %s\n' "$app_bundle"

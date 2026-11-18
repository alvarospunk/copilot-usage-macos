#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
app_bundle="$HOME/Applications/Copilot Usage.app"
resource_directory="$app_bundle/Contents/Resources"
helper="$resource_directory/usage-percent.sh"
support_directory="$HOME/Library/Application Support/com.jgarri.copilot-usage"
trusted_directory_file="$support_directory/copilot-cli-working-directory"

fail() {
	print -u2 -- "Error: $*"
	exit 1
}

[[ "$(/usr/bin/uname -s)" == "Darwin" ]] || fail "Copilot Usage can only be installed on macOS."

macos_major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f1)
[[ $macos_major == <-> && $macos_major -ge 13 ]] || fail "macOS 13 or later is required."

swift_binary=$(whence -p swift || true)
[[ -n $swift_binary ]] || fail "Swift 6 and Xcode Command Line Tools are required to build the app."
swift_major=$("$swift_binary" --version | /usr/bin/awk 'NR == 1 { for (field = 1; field <= NF; field++) if ($field == "version") { split($(field + 1), parts, /\./); print parts[1]; exit } }')
[[ $swift_major == <-> && $swift_major -ge 6 ]] || fail "Swift 6 or later is required to build the app."

[[ -x /usr/bin/expect ]] || fail "The Copilot usage helper requires /usr/bin/expect."

export PATH="$HOME/.local/bin:$HOME/.local/share/gh/copilot:/opt/homebrew/bin:/usr/local/bin:$PATH"
copilot_binary=$(whence -p copilot || true)
[[ -n $copilot_binary ]] || fail "Install the GitHub Copilot CLI and authenticate it before installing Copilot Usage."

sh "$script_dir/build-app.sh" "$app_bundle"

mkdir -p "$support_directory"
trusted_directory=""
if [[ -f $trusted_directory_file ]]; then
	trusted_directory=$(<"$trusted_directory_file")
fi

if [[ $trusted_directory != "$resource_directory" ]] || ! sh "$helper" >/dev/null 2>&1; then
	print -- "Copilot CLI must be authenticated and trust the app's Resources folder."
	print -- "The CLI will open in that folder now. Confirm trust if prompted, wait for the usage view, then exit with Ctrl+C."
	(
		cd "$resource_directory"
		"$copilot_binary" -i /usage
	) || true
	sh "$helper" >/dev/null || fail "Copilot CLI is not ready. Authenticate it, trust the app Resources folder, and run this installer again."
	print -r -- "$resource_directory" > "$trusted_directory_file"
fi

/usr/bin/open -a "$app_bundle"
# Copilot Usage for macOS

Copilot Usage is a macOS menu-bar app that displays current GitHub Copilot Plan usage and monthly working-day pacing.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools with Swift 6
- GitHub Copilot CLI installed and authenticated
- `/usr/bin/expect` available

The first Copilot CLI run may ask you to trust this repository directory. Review the prompt and choose whether to trust it.

## Build and Run

Build and open the menu-bar app from this repository root:

```sh
sh run.sh
```

The app is installed at `~/Applications/Copilot Usage.app`. It uses local ad-hoc signing for this machine; distributing it to other users requires proper Developer ID signing and notarization.

To print only the current Copilot Plan percentage to the terminal:

```sh
sh usage-percent.sh
```

The command prints one percentage line, suitable for command substitution, for example `usage=$(sh usage-percent.sh)`. It runs the authenticated `copilot -i /usage` in a hidden pseudoterminal and extracts only monthly Plan usage, not Session or Weekly usage. It does not use OCR, capture the screen, or interfere with existing Copilot sessions. It times out after 45 seconds and terminates only the CLI process it started.

The app has bundle identifier `com.jgarri.copilot-usage` and stays resident in the menu bar with a frog icon. Clicking the icon opens the usage popover.

On the first manual run, the app installs a per-user LaunchAgent that checks at 09:00 local time, Monday through Friday. On the first eligible weekday of each month, it fetches national and Comunidad de Madrid holiday suggestions from Nager.Date, then asks you to edit the list. Add Madrid city holidays or personal days off as `YYYY-MM-DD` dates separated by commas. Cancel leaves the month unconfigured, so the reminder retries on a later weekday. The final list is stored locally in `~/Library/Application Support/com.jgarri.copilot-usage/holidays.json`.

Nager.Date is a third-party source and does not include Madrid city-specific holidays. The request sends only the country code and year. If it is unavailable, the dialog starts with an empty list for manual entry.

The popover shows the current percentage, “Today you can spend until …”, “...% per working day”, and working days left. It omits the under/over-pace and total-remaining rows. The last successful check time is shown beneath the figures. A clockwise-arrow button with the tooltip “Refresh Copilot usage” runs the bundled `usage-percent.sh` command and updates the figures from the active account's Plan usage. The app does not open VS Code, capture the screen, or move the cursor. Copilot CLI must be installed and authenticated. The app starts it from the trusted repository directory used to build the bundle and adds common CLI install locations to its search path.

Usage is cached in the user's preferences. The app checks every minute by default. **Update frequency**, next to **Edit Holidays**, selects a persisted interval of 1, 5, 15, 30, or 60 minutes. Opening the popover reuses a reading within that interval; pressing the refresh arrow always requests a fresh CLI reading unless a read is already running. A refresh can return the same number: the app shows the Plan percentage reported by Copilot CLI, which may differ from other Copilot clients. Scheduled holiday prompts do not capture the screen.

The first manual app launch asks whether to always allow the app or ask for permission on every launch. Choosing **Ask Every Time** shows a consent dialog each time Copilot Usage opens; **Always Allow** saves the choice locally and skips future prompts. Cancel exits without saving a choice. To show the first-launch choice again, run `defaults delete com.jgarri.copilot-usage usage.consentMode` and reopen the app. Screen Recording permission is not required.

Scheduled holiday checks do not open VS Code or capture the screen.

After changing source code, rebuild and re-sign the installed app:

```sh
sh build-app.sh
```

Run the local checks:

```sh
sh test.sh
sh test-app-bundle.sh
sh test-cli-plan-percent.sh
sh -n run.sh usage-percent.sh build-app.sh test.sh test-app-bundle.sh test-cli-plan-percent.sh
```

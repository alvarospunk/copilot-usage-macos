# Usage and Maintenance

## Menu Bar

The menu bar shows current usage and today's target, such as `51% / 52.6%`. Open the panel for daily allowance, working days left, and the last successful check.

- The refresh arrow requests a new CLI reading unless a read is already running.
- **Update frequency** saves an interval of 1, 5, 15, 30, or 60 minutes.
- **Hide current usage** and **Hide target daily usage** control the menu-bar percentages. Select both to leave only the icon.
- **Edit Holidays** changes the dates excluded from your working-day budget.

## Holidays

The app suggests national and Comunidad de Madrid holidays from Nager.Date. Add Madrid city holidays and personal days off as comma-separated `YYYY-MM-DD` dates. If suggestions are unavailable, enter dates manually.

The app installs a per-user 09:00 local-time holiday reminder. Canceling monthly setup leaves the month unconfigured so a later reminder can retry.

## Privacy and Permissions

No Screen Recording, Accessibility, or microphone permission is required. The app runs `copilot -i /usage` in a hidden pseudoterminal; it does not use OCR, capture the screen, move the cursor, or open VS Code.

The app's own startup consent dialog is not a macOS privacy permission. **Always Allow** saves consent; **Ask Every Time** prompts on each launch. To reset it:

```sh
defaults delete com.jgarri.copilot-usage usage.consentMode
```

Preferences and the last successful reading stay in local macOS preferences. Holiday dates stay in `~/Library/Application Support/com.jgarri.copilot-usage/holidays.json`. Copilot CLI manages its own authentication. Holiday requests send only the year and country code to Nager.Date.

## Troubleshooting

**Usage does not change:** a successful refresh can return the same value. Check the last-update time. The app displays CLI Plan usage, which may differ from other Copilot clients; Session and Weekly usage are not used.

**Reading times out:** complete [CLI setup](installation.md#cli-setup). Reads time out after 45 seconds. The helper terminates only the CLI process it starts.

**CLI not found:** ensure `copilot` is installed in your PATH or a supported location: `~/.local/bin`, `~/.local/share/gh/copilot`, `/opt/homebrew/bin`, or `/usr/local/bin`.

## Development

Rebuild using your [installation option](installation.md). Quit and reopen the resident app to run the new binary.

Run checks from the repository root:

```sh
sh test.sh
sh test-app-bundle.sh
sh test-cli-plan-percent.sh
zsh -n install.zsh
sh -n usage-percent.sh build-app.sh test.sh test-app-bundle.sh test-cli-plan-percent.sh
```

For a one-off terminal reading, run `sh usage-percent.sh` from the repository. Copilot CLI may request trust for that folder separately from the installed app.
# Copilot Usage for macOS

GitHub Copilot usage and today's working-day target, right in your menu bar.

## Prerequisites

- macOS 13+, authenticated **Copilot CLI**, and `/usr/bin/expect`.
- Building from source also needs **Xcode Command Line Tools with Swift 6+**.
- **No Screen Recording or Accessibility permissions. No `gh` required.**

## Installation

### Portable App

Already have a compiled **Copilot Usage.app**? Copy it to `~/Applications` and open it. No shell or Swift needed to run it. **No prebuilt download is published yet.** See [portable setup](docs/installation.md#portable-app).

### Zsh (Recommended)

From the repository folder:

```sh
zsh install.zsh
```

Builds, installs, checks Copilot CLI setup, and opens the app.

### Bash

From the repository folder:

```sh
bash build-app.sh
```

Builds and installs the app. Then [complete CLI setup and open it](docs/installation.md#bash).

## First Use

Allow the app's startup prompt, configure your holidays, and click the menu-bar icon. Usage refreshes every minute; the panel lets you change frequency or hide either percentage.

## More Information

- [Installation, CLI setup, and Homebrew status](docs/installation.md)
- [Settings, privacy, troubleshooting, and development](docs/usage.md)

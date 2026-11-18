# Installation

## Prerequisites

All installation options require macOS 13 or later, `/usr/bin/expect`, network access to GitHub Copilot, and the standalone `copilot` CLI authenticated to an account with Copilot access. The GitHub CLI (`gh`) is not required.

Source builds additionally require Xcode Command Line Tools with Swift 6 or later. These tools also provide `make` for the portable build. Zsh is required only for the Zsh installer; Bash can run the build script instead.

## Portable App

No prebuilt release is published yet. Build the app from the repository root:

```sh
make build
```

The compiled bundle is `dist/Copilot Usage.app`. This command does not replace your installed app. It builds for your Mac's architecture, so only copy it to a compatible Mac.

Copy **Copilot Usage.app** to `~/Applications`, complete [CLI setup](#cli-setup), and open the app. Keep the whole bundle intact. It does not need the source checkout or Swift at runtime.

Locally built bundles use ad-hoc signing. Copying one to another Mac does not provide Developer ID signing or notarization; Gatekeeper may block it. Do not disable macOS security protections.

## Zsh

From the repository root:

```sh
zsh install.zsh
```

The installer checks prerequisites, builds and signs the app locally, installs it in `~/Applications`, prepares Copilot CLI trust interactively, verifies a usage reading, and opens the app. Rerun it to rebuild after source updates.

## Bash

From the repository root:

```sh
bash build-app.sh
```

This builds and installs the same app, without the Zsh installer's prerequisite and interactive setup checks. Complete [CLI setup](#cli-setup), then launch it:

```sh
open "$HOME/Applications/Copilot Usage.app"
```

## CLI Setup

Run the CLI from the installed app's Resources folder:

```sh
cd "$HOME/Applications/Copilot Usage.app/Contents/Resources"
copilot -i /usage
```

Authenticate and review the folder-trust prompt if shown. Once the usage view appears, exit the CLI, then verify the helper from that same folder:

```sh
sh usage-percent.sh
```

It should print a percentage. Trust is never granted automatically. Moving the app may require trusting its new Resources folder.

## Homebrew

Homebrew installation is not available yet. A personal tap is a possible next step; a public release would allow unauthenticated downloads. Private distribution would need authenticated downloads. An official Homebrew Cask must meet Homebrew's Gatekeeper requirements; the current local ad-hoc signing is not a notarized Developer ID distribution.

See the [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook) and [Apple notarization requirements](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).
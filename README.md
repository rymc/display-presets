# Display Presets

Display Presets is a small macOS menu bar app for saving and switching display
arrangements.

It is designed for setups where you regularly switch between monitor layouts:
docked vs. undocked, mirrored vs. extended, presentation mode, or any other
display arrangement you can configure in System Settings.

## Features

- Save the current display arrangement as a named preset.
- Switch presets from the menu bar.
- Keep the app hidden from the Dock.
- Optionally open at login.
- Store presets locally in Application Support.
- No accounts, telemetry, network calls, or cloud sync.

Display Presets restores macOS display arrangements. It does not switch a
monitor's physical HDMI, DisplayPort, or USB-C input source.

## Requirements

- macOS 13 Ventura or later.
- [`displayplacer`](https://github.com/jakehilborn/displayplacer), installed
  separately.

Display Presets does not bundle `displayplacer`. Install it separately, most
commonly with Homebrew:

```sh
brew install displayplacer
```

## Install

Display Presets is source-first for now. Public binary downloads are not
provided because the app is not Developer ID signed or notarized.

Build and run locally:

```sh
make deps
make run
```

Run the full local verification suite:

```sh
make check
```

## Usage

1. Arrange your displays in System Settings.
2. Open `Configure Presets...` from the menu bar.
3. Name the arrangement and click `Save`.
4. Choose the saved preset from the menu bar whenever you want to restore it.

For example, common presets might be:

- `HDMI`
- `USB-C`
- `Presentation`
- `Mirrored`

Use `Open at Login` in the menu to start the app automatically when you sign in.
If you are running the temporary build copy, the menu offers
`Install in Applications...` first. That copies the app to `~/Applications`,
opens the installed copy, and then you can enable `Open at Login`.

## Build

Regenerate the app icon after changing icon artwork:

```sh
make app-icon
```

```sh
make build
```

Install the locally built app into `~/Applications`:

```sh
make install
open ~/Applications/Display\ Presets.app
```

Local builds are ad-hoc signed for development. They are intended for people who
build the app themselves from source.

The Makefile includes packaging and notarization targets for a possible future
signed release, but those require an Apple Developer ID Application certificate:

```sh
make package SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
```

To notarize, first configure an Apple notarytool keychain profile, then run:

```sh
make notarize \
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  NOTARY_PROFILE="DisplayPresets"
```

Build artifacts are written to `dist/`.

## Design

Display Presets is a native AppKit `LSUIElement` app. It creates one menu bar
status item and stores presets as plain text files under Application Support.
The app only shells out to the local `displayplacer` executable when saving or
applying a preset.

See `docs/ARCHITECTURE.md` for a short implementation map.

## Privacy

Display Presets stores preset files locally at:

```text
~/Library/Application Support/Display Presets
```

It does not collect analytics, send telemetry, contact a server, or require an
account.

## Third-Party Software

Display Presets depends on `displayplacer`, an MIT-licensed command-line utility
for reading and applying display arrangements. See
`THIRD_PARTY_NOTICES.md` for details.

## Notes

Display Presets shows the last preset it applied. It does not read a monitor's
physical input source directly.

Some display identifiers can change when macOS wakes displays in a different
order. If a saved preset stops applying correctly, recreate that preset with the
current display arrangement.

For common setup and runtime issues, see `docs/TROUBLESHOOTING.md`.

## License

MIT. See `LICENSE`.

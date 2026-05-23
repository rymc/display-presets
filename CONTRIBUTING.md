# Contributing

Thanks for considering a contribution to Display Presets.

## Development Setup

```sh
brew install displayplacer
make build
make run
```

The app is intentionally small: AppKit views live in `Sources/`, bundle metadata
lives in `App/Info.plist`, and release packaging is handled by `Makefile`.

## Before Opening a Pull Request

Run:

```sh
make check
```

For UI changes, also launch the app and inspect the configuration window at the
minimum supported content size.

## Scope

Good contributions are focused and practical:

- macOS display arrangement reliability.
- Clearer onboarding for direct-download users.
- Better diagnostics when `displayplacer` cannot apply a preset.
- Native macOS polish that keeps the app simple.

Avoid adding accounts, cloud sync, analytics, or background networking.

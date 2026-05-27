# Architecture

Display Presets is intentionally small and local-first. It is a native AppKit
menu bar app with no server component, account system, analytics, or bundled
third-party binaries.

## Runtime Model

- `Sources/main.swift` starts an accessory `NSApplication`.
- `AppDelegate` owns the `NSStatusItem`, menu construction, profile switching
  state, and the configuration window.
- `ProfilesWindowController` hosts the configuration UI for saving and deleting
  presets.
- `DisplayplacerService` is the only integration point with `displayplacer`.
- `ProfileStore` reads and writes local preset files under Application Support.

## Data Storage

Presets are stored in:

```text
~/Library/Application Support/Display Presets
```

The important files are:

- `profiles/*.profile`: one saved `displayplacer` argument list per preset.
- `order.txt`: menu ordering for saved presets.
- `state.txt`: the last preset successfully applied by the app.

The app can migrate data from the old private app name, `Display Mode Switch`.
That migration is local only and does not delete user preset data.

## Menu Bar Identity

The app uses bundle id `io.github.rymc.display-presets` and status item
autosave name `DisplayPresetsStatusItem`. Menu bar managers can use the combined
identifier:

```text
io.github.rymc.display-presets:DisplayPresetsStatusItem
```

Display Presets clears the saved `NSStatusItem` preferred-position key before
creating or recreating the item. That keeps a stable identity for tools such as
Thaw, but lets AppKit place the item in the current menu bar coordinate space
after the app changes the display layout.

## Dependency Boundary

Display Presets depends on `displayplacer` at runtime, but it does not bundle or
modify `displayplacer`. The app captures the command arguments printed by
`displayplacer list`, stores them locally, and later passes those arguments back
to `displayplacer`.

Physical monitor input switching is intentionally out of scope. On many display
setups, macOS and `displayplacer` can restore arrangements but cannot safely
control the monitor's HDMI, DisplayPort, or USB-C input source.

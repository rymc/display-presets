# Troubleshooting

## The Menu Bar Item Is Missing

Display Presets is a menu bar app, so it does not show a normal Dock icon or
main app window while idle.

Check whether the app is running:

```sh
pgrep -fl DisplayPresets
```

If you use a menu bar manager such as Thaw, Bartender, Ice, or Hidden Bar, check
that the item is not hidden. The stable menu bar identifier is:

```text
com.ryanmcconville.display-presets.menu:DisplayPresetsStatusItem
```

If the app is running but no item is visible, quit and reopen it:

```sh
pkill -x DisplayPresets
open ~/Applications/Display\ Presets.app
```

## `displayplacer` Is Missing

Install the runtime dependency:

```sh
brew install displayplacer
```

You can also point the app at a custom executable path:

```sh
DISPLAYPLACER=/path/to/displayplacer open ~/Applications/Display\ Presets.app
```

## A Preset No Longer Applies Correctly

macOS display identifiers can change after unplugging displays, changing docks,
or waking from sleep. Recreate the preset from the current working display
arrangement:

1. Arrange displays in System Settings.
2. Open `Configure Presets...`.
3. Save the preset again with the same name and confirm replacement.

If the menu shows an error like `Unable to find screen ...`, the saved preset
references a display id that macOS no longer exposes. That usually means the
display was reconnected through a different port, dock, adapter, or input path.
Re-saving the preset updates the stored ids.

## Open at Login Is Disabled

Open at Login is only available when the app is running from `/Applications` or
`~/Applications`. If you launch from the build directory, choose `Install in
Applications...` from the menu first.

## Local Verification

Run the same checks used by CI:

```sh
make check
```

For UI issues, also launch the app manually and inspect the configuration
window:

```sh
make run
```

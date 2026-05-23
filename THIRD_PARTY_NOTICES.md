# Third-Party Notices

Display Presets depends on the following third-party software at runtime.

## displayplacer

- Project: <https://github.com/jakehilborn/displayplacer>
- License: MIT
- Purpose: Read and apply macOS display arrangements.
- Distribution: Not bundled with Display Presets. Installed separately, usually
  through Homebrew.

`displayplacer` is maintained by its upstream project. Display Presets invokes
the installed `displayplacer` executable and stores the arguments returned by
`displayplacer list` as local presets.

If Display Presets ever bundles `displayplacer` in a future release, this file
must be updated to include the full upstream copyright and license notice in the
distributed app archive.

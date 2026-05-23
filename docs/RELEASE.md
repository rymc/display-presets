# Release Notes

Display Presets is source-first for now.

Do not publish unsigned or ad-hoc-signed app archives as the recommended install
path. Downloaded macOS apps should be Developer ID signed and notarized before
they are presented to normal users.

## Source Release

For now, a GitHub release can be used to mark source milestones only:

1. Update `VERSION` in `Makefile` if needed.
2. Update `CFBundleShortVersionString` and `CFBundleVersion` in
   `App/Info.plist` if needed.
3. Update `CHANGELOG.md`.
4. Verify:

   ```sh
   make clean
   make check
   ```

5. Tag the source:

   ```sh
   git tag "v0.1.0"
   ```

6. In the GitHub release notes, tell users to build locally:

   ```sh
   brew install displayplacer
   make build
   open "build/Display Presets.app"
   ```

## Future Binary Release

If a Developer ID is available later:

1. Create an Apple Developer ID Application certificate.
2. Configure notarytool credentials:

   ```sh
   xcrun notarytool store-credentials DisplayPresets \
     --apple-id "you@example.com" \
     --team-id "TEAMID" \
     --password "app-specific-password"
   ```

3. Build and notarize:

   ```sh
   make notarize \
     SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
     NOTARY_PROFILE="DisplayPresets"
   ```

4. Verify the archive on a clean macOS account or VM:

   ```sh
   spctl --assess --type execute --verbose "Display Presets.app"
   xcrun stapler validate "Display Presets.app"
   ```

5. Upload `dist/Display-Presets-0.1.0.zip` to GitHub Releases with its SHA-256.

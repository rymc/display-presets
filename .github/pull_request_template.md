## Summary


## Verification

- [ ] `make build`
- [ ] `plutil -lint App/Info.plist`
- [ ] `codesign --verify --deep --strict --verbose=2 "build/Display Presets.app"`
- [ ] Manually inspected the app if UI changed

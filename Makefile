APP_NAME := Display Presets
LEGACY_APP_NAME := Display Mode Switch
EXECUTABLE := DisplayPresets
BUNDLE_IDENTIFIER := io.github.rymc.display-presets
VERSION := 0.1.0
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
DIST_DIR := dist
ZIP_NAME := Display-Presets-$(VERSION).zip
APP_RESOURCES_DIR := $(APP_DIR)/Contents/Resources
SIGN_IDENTITY ?= -
NOTARY_PROFILE ?= DisplayPresets
SWIFTC_FLAGS ?= -O -warnings-as-errors

ifeq ($(SIGN_IDENTITY),-)
CODESIGN_ARGS := --force --deep --sign -
else
CODESIGN_ARGS := --force --deep --options runtime --timestamp --sign "$(SIGN_IDENTITY)"
endif

.PHONY: build run install package notarize clean deps lint verify-signature check app-icon

build:
	mkdir -p "$(APP_DIR)/Contents/MacOS"
	mkdir -p "$(APP_RESOURCES_DIR)"
	swiftc $(SWIFTC_FLAGS) -framework AppKit -o "$(APP_DIR)/Contents/MacOS/$(EXECUTABLE)" Sources/*.swift
	cp App/Info.plist "$(APP_DIR)/Contents/Info.plist"
	cp -R App/Resources/. "$(APP_RESOURCES_DIR)/"
	codesign $(CODESIGN_ARGS) "$(APP_DIR)"

run: build
	open "$(APP_DIR)"

install: build
	mkdir -p "$(HOME)/Applications"
	rm -rf "$(HOME)/Applications/$(APP_NAME).app"
	rm -rf "$(HOME)/Applications/$(LEGACY_APP_NAME).app"
	cp -R "$(APP_DIR)" "$(HOME)/Applications/"

package: clean build
	mkdir -p "$(DIST_DIR)"
	ditto -c -k --sequesterRsrc --keepParent "$(APP_DIR)" "$(DIST_DIR)/$(ZIP_NAME)"
	shasum -a 256 "$(DIST_DIR)/$(ZIP_NAME)" > "$(DIST_DIR)/$(ZIP_NAME).sha256"

notarize: clean build
	mkdir -p "$(DIST_DIR)"
	ditto -c -k --sequesterRsrc --keepParent "$(APP_DIR)" "$(DIST_DIR)/notary-upload.zip"
	xcrun notarytool submit "$(DIST_DIR)/notary-upload.zip" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(APP_DIR)"
	rm -f "$(DIST_DIR)/notary-upload.zip"
	ditto -c -k --sequesterRsrc --keepParent "$(APP_DIR)" "$(DIST_DIR)/$(ZIP_NAME)"
	shasum -a 256 "$(DIST_DIR)/$(ZIP_NAME)" > "$(DIST_DIR)/$(ZIP_NAME).sha256"

deps:
	command -v displayplacer >/dev/null || brew install displayplacer

app-icon:
	swift tools/generate-app-icon.swift

lint:
	plutil -lint App/Info.plist
	test "$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' App/Info.plist)" = "$(BUNDLE_IDENTIFIER)"

verify-signature: build
	codesign --verify --deep --strict --verbose=2 "$(APP_DIR)"

check: lint verify-signature

clean:
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)"

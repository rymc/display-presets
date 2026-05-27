import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum StatusItemPlacement {
        static let autosaveName = "DisplayPresetsStatusItem"
        static let preferredPositionKey = "NSStatusItem Preferred Position \(autosaveName)"
        static let visibilityKey = "NSStatusItem Visible \(autosaveName)"
    }

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var profiles: [Profile] = []
    private var selectedProfileName: String?
    private var menuHeaderTitle = "Loading..."
    private var statusButtonTitle = AppConstants.appName
    private var isSwitching = false
    private var needsProfileReload = false
    private var profileLoadGeneration = 0
    private var pendingStatusItemRefresh: DispatchWorkItem?
    private lazy var profilesWindow = ProfilesWindowController { [weak self] in
        self?.reloadProfiles()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.delegate = self
        rebuildMenu()
        installStatusItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        let shouldForceConfiguration = ProcessInfo.processInfo.arguments.contains("--configure")
        reloadProfiles(openConfigurationIfEmpty: !shouldForceConfiguration)

        if shouldForceConfiguration {
            DispatchQueue.main.async { [weak self] in
                self?.showConfigurationWindow()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showConfigurationWindow()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        resetStatusItemPlacement()
    }

    @objc private func screenParametersChanged() {
        scheduleStatusItemRefresh()
    }

    @objc private func applyProfile(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let profile = profiles.first(where: { $0.name == name })
        else {
            return
        }

        runProfile(profile)
    }

    @objc private func configureModes() {
        showConfigurationWindow()
    }

    @objc private func toggleOpenAtLogin(_ sender: NSMenuItem) {
        do {
            try LoginItem.setEnabled(sender.state == .off)
            rebuildMenu()
        } catch {
            setStatus("Error", "Error: \(error.localizedDescription)")
            rebuildMenu()
        }
    }

    @objc private func installApp() {
        setStatus("Installing", "Installing in Applications...")
        rebuildMenu()

        AppInstaller.installAndRelaunch { [weak self] result in
            switch result {
            case .success:
                NSApp.terminate(nil)
            case .failure(let error):
                self?.setStatus("Error", "Error: \(error.localizedDescription)")
                self?.rebuildMenu()
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func reloadProfiles(updateStatus: Bool = true, openConfigurationIfEmpty: Bool = false) {
        guard !isSwitching else {
            needsProfileReload = true
            return
        }

        profileLoadGeneration += 1
        let generation = profileLoadGeneration

        DispatchQueue.global(qos: .userInitiated).async {
            let loadedProfiles = ProfileCatalog.loadProfiles()
            let loadedSelectedProfileName = ProfileStore.loadState()

            DispatchQueue.main.async { [weak self] in
                guard let self, generation == self.profileLoadGeneration else { return }

                guard !self.isSwitching else {
                    self.needsProfileReload = true
                    return
                }

                self.applyLoadedProfiles(
                    loadedProfiles,
                    selectedProfileName: loadedSelectedProfileName,
                    updateStatus: updateStatus
                )

                if openConfigurationIfEmpty, self.profiles.isEmpty {
                    self.showConfigurationWindow()
                }
            }
        }
    }

    private func applyLoadedProfiles(
        _ profiles: [Profile],
        selectedProfileName loadedSelectedProfileName: String?,
        updateStatus: Bool
    ) {
        self.profiles = profiles
        selectedProfileName = loadedSelectedProfileName

        if let selectedProfileName,
           !profiles.contains(where: { $0.name == selectedProfileName }) {
            self.selectedProfileName = nil
        }

        if updateStatus {
            updateStatusFromProfiles()
        }

        rebuildMenu()
    }

    private func updateStatusFromProfiles() {
        if let selectedProfileName {
            setStatus(selectedProfileName, "Current Preset: \(selectedProfileName)")
        } else if profiles.isEmpty {
            setStatus("Set Up", "No Presets Saved")
        } else {
            setStatus("Choose", "Choose a Preset")
        }
    }

    private func installStatusItem() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        resetStatusItemPlacement()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = StatusItemPlacement.autosaveName
        statusItem.isVisible = true
        self.statusItem = statusItem
        configureStatusItem()
        statusItem.menu = menu
        pendingStatusItemRefresh = nil
    }

    private func resetStatusItemPlacement() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StatusItemPlacement.preferredPositionKey)
        defaults.set(true, forKey: StatusItemPlacement.visibilityKey)
    }

    private func scheduleStatusItemRefresh() {
        pendingStatusItemRefresh?.cancel()

        let refresh = DispatchWorkItem { [weak self] in
            self?.installStatusItem()
        }
        pendingStatusItemRefresh = refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: refresh)
    }

    private func configureStatusItem() {
        guard let button = statusItem?.button else { return }

        if let image = NSImage(systemSymbolName: "display.2", accessibilityDescription: AppConstants.appName) {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.title = statusButtonTitle
        }

        button.toolTip = "\(AppConstants.appName): \(statusButtonTitle)"
        button.setAccessibilityLabel("\(AppConstants.appName): \(statusButtonTitle)")
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        if shouldShowStatusHeader {
            let statusText = NSMenuItem(title: menuHeaderTitle, action: nil, keyEquivalent: "")
            statusText.isEnabled = false
            menu.addItem(statusText)
            menu.addItem(.separator())
        }

        if profiles.isEmpty {
            let empty = NSMenuItem(title: "No presets saved", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for profile in profiles {
                let item = NSMenuItem(title: profile.name, action: #selector(applyProfile(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = profile.name
                item.state = profile.name == selectedProfileName ? .on : .off
                item.isEnabled = !isSwitching
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let configure = NSMenuItem(title: "Configure Presets...", action: #selector(configureModes), keyEquivalent: ",")
        configure.target = self
        menu.addItem(configure)

        if LoginItem.canEnableCurrentApp || LoginItem.isEnabled || LoginItem.requiresApproval {
            let openAtLogin = NSMenuItem(title: openAtLoginTitle, action: #selector(toggleOpenAtLogin(_:)), keyEquivalent: "")
            openAtLogin.target = self
            openAtLogin.state = LoginItem.requiresApproval ? .mixed : (LoginItem.isEnabled ? .on : .off)
            openAtLogin.isEnabled = true
            menu.addItem(openAtLogin)
        } else {
            let install = NSMenuItem(title: "Install in Applications...", action: #selector(installApp), keyEquivalent: "")
            install.target = self
            menu.addItem(install)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private var openAtLoginTitle: String {
        LoginItem.requiresApproval
            ? "Open at Login (Approve in System Settings)"
            : "Open at Login"
    }

    private var shouldShowStatusHeader: Bool {
        menuHeaderTitle.hasPrefix("Error:")
            || menuHeaderTitle == "Switching Presets..."
            || menuHeaderTitle == "Installing in Applications..."
    }

    private func showConfigurationWindow() {
        profilesWindow.showWindow(nil)
    }

    private func runProfile(_ profile: Profile) {
        guard !isSwitching else { return }

        isSwitching = true
        setStatus("Switching", "Switching Presets...")
        rebuildMenu()

        DisplayModeWorkflow.apply(profile) { [weak self] result in
            self?.finishSwitch(result)
        }
    }

    private func finishSwitch(_ result: Result<Profile, Error>) {
        isSwitching = false

        switch result {
        case .success(let profile):
            selectedProfileName = profile.name
            ProfileStore.saveState(profile.name)
            setStatus(profile.name, "Current Preset: \(profile.name)")
            scheduleStatusItemRefresh()
        case .failure(let error):
            setStatus("Error", "Error: \(error.localizedDescription)")
        }

        if needsProfileReload {
            needsProfileReload = false
            reloadProfiles(updateStatus: false)
        } else {
            rebuildMenu()
        }
    }

    private func setStatus(_ buttonTitle: String, _ menuTitle: String) {
        menuHeaderTitle = menuTitle
        statusButtonTitle = buttonTitle
        guard let button = statusItem?.button else { return }

        if button.image == nil {
            button.title = buttonTitle
        }

        button.toolTip = "\(AppConstants.appName): \(buttonTitle)"
        button.setAccessibilityLabel("\(AppConstants.appName): \(buttonTitle)")
    }
}

import AppKit

final class ProfilesWindowController: NSWindowController {
    private let displayView: DisplayModesView
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        self.displayView = DisplayModesView()

        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 500,
                height: DisplayModesView.preferredContentHeight(forProfileCount: 2)
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppConstants.appName
        window.titleVisibility = .hidden
        window.contentView = displayView
        window.initialFirstResponder = displayView
        window.contentMinSize = NSSize(
            width: 500,
            height: DisplayModesView.preferredContentHeight(forProfileCount: 2)
        )
        window.center()

        super.init(window: window)
        configureActions()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        window?.makeFirstResponder(displayView)
        NSApp.activate(ignoringOtherApps: true)
        displayView.setStatus("", isError: false)
        reloadProfiles()
        updateDependencyStatus()
    }

    private func configureActions() {
        displayView.onSaveRequested = { [weak self] name in
            self?.captureProfile(named: name)
        }
        displayView.onDeleteProfile = { [weak self] name in
            self?.deleteProfile(named: name)
        }
    }

    private func captureProfile(named rawName: String) {
        guard updateDependencyStatus() else {
            return
        }

        guard !rawName.isEmpty else {
            displayView.setStatus("Enter a preset name first.", isError: true)
            displayView.focusProfileName()
            return
        }

        let normalizedName = ProfileStore.safeName(rawName)
        let isReplacing = ProfileStore.profileExists(name: normalizedName)
        guard !isReplacing || confirmReplaceProfile(named: normalizedName) else {
            return
        }

        displayView.setStatus("Saving current layout...", isError: false)
        displayView.setSaving(true)

        DisplayModeWorkflow.captureCurrentMode(named: normalizedName, allowOverwrite: isReplacing) { [weak self] result in
            guard let self else { return }

            displayView.setSaving(false)

            switch result {
            case .success(let name):
                displayView.clearProfileName()
                displayView.setStatus("Saved \(name).", isError: false)
                reloadProfiles()
                onChange()
            case .failure(let error):
                displayView.setStatus(error.localizedDescription, isError: true)
            }
        }
    }

    private func deleteProfile(named name: String) {
        let alert = NSAlert()
        alert.messageText = "Delete \(name)?"
        alert.informativeText = "This removes the saved preset. Your current display arrangement will not change."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        ProfileStore.deleteProfile(name: name)
        displayView.setStatus("Deleted \(name).", isError: false)
        reloadProfiles()
        onChange()
    }

    private func reloadProfiles() {
        let profiles = ProfileCatalog.loadProfiles()
        displayView.setProfiles(profiles)
        resizeWindow(forProfileCount: profiles.count)
    }

    @discardableResult
    private func updateDependencyStatus() -> Bool {
        guard DisplayplacerService.executablePath() == nil else {
            return true
        }

        displayView.setStatus(DisplayplacerService.missingDependencyMessage, isError: true)
        return false
    }

    private func resizeWindow(forProfileCount profileCount: Int) {
        guard let window else { return }

        let currentFrame = window.frame
        let preferredHeight = DisplayModesView.preferredContentHeight(forProfileCount: profileCount)
        window.contentMinSize = NSSize(width: 500, height: preferredHeight)

        let currentContentWidth = window.contentView?.bounds.width ?? 500
        let contentSize = NSSize(
            width: max(currentContentWidth, 500),
            height: preferredHeight
        )
        let targetFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))
        let frame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.maxY - targetFrame.height,
            width: targetFrame.width,
            height: targetFrame.height
        )
        window.setFrame(frame, display: true, animate: false)
    }

    private func confirmReplaceProfile(named name: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Replace \(name)?"
        alert.informativeText = "A saved preset with this name already exists. Replacing it updates the saved display arrangement."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")

        return alert.runModal() == .alertFirstButtonReturn
    }
}

import Foundation
import ServiceManagement

enum LoginItem {
    private static let installMessage = "Install the app in Applications before enabling Open at Login."

    private static var legacyLaunchAgentURLs: [URL] {
        AppConstants.legacyBundleIdentifiers.map {
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
                .appendingPathComponent("\($0).plist")
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
            || legacyLaunchAgentURLs.contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    static var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static var canEnableCurrentApp: Bool {
        isRunningFromInstalledApplicationsDirectory
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }

    private static func enable() throws {
        guard canEnableCurrentApp else {
            throw loginItemError(installMessage)
        }

        try SMAppService.mainApp.register()
        try removeLegacyLaunchAgentIfPresent()

        if SMAppService.mainApp.status == .requiresApproval {
            throw loginItemError("Approve \(AppConstants.appName) in System Settings > General > Login Items.")
        }
    }

    private static func disable() throws {
        if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }

        try removeLegacyLaunchAgentIfPresent()
    }

    private static func removeLegacyLaunchAgentIfPresent() throws {
        for legacyLaunchAgentURL in legacyLaunchAgentURLs {
            if FileManager.default.fileExists(atPath: legacyLaunchAgentURL.path) {
                try FileManager.default.removeItem(at: legacyLaunchAgentURL)
            }
        }
    }

    private static var isRunningFromInstalledApplicationsDirectory: Bool {
        let bundlePath = Bundle.main.bundleURL.standardizedFileURL.path
        let allowedPrefixes = [
            "/Applications/",
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .standardizedFileURL
                .path + "/"
        ]

        return Bundle.main.bundleURL.pathExtension == "app"
            && allowedPrefixes.contains { bundlePath.hasPrefix($0) }
    }

    private static func loginItemError(_ message: String) -> NSError {
        NSError(
            domain: AppConstants.appName,
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

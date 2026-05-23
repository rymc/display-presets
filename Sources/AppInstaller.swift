import Foundation

enum AppInstaller {
    static var installedAppURL: URL {
        homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("\(AppConstants.appName).app", isDirectory: true)
    }

    private static var homeDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    private static var legacyInstalledAppURL: URL {
        homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("\(AppConstants.legacyAppName).app", isDirectory: true)
    }

    static func installAndRelaunch(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let sourceURL = Bundle.main.bundleURL.standardizedFileURL
                let destinationURL = installedAppURL.standardizedFileURL

                guard sourceURL.path != destinationURL.path else {
                    complete(.success(()), completion: completion)
                    return
                }

                try FileManager.default.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                try removeLegacyInstalledAppIfNeeded(sourceURL: sourceURL, destinationURL: destinationURL)
                try scheduleInstalledAppLaunch(at: destinationURL)
                complete(.success(()), completion: completion)
            } catch {
                complete(.failure(error), completion: completion)
            }
        }
    }

    private static func scheduleInstalledAppLaunch(at url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            "sleep 0.5; exec /usr/bin/open -n \"$1\" --args --configure",
            "display-presets-open",
            url.path
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
    }

    private static func removeLegacyInstalledAppIfNeeded(sourceURL: URL, destinationURL: URL) throws {
        let legacyURL = legacyInstalledAppURL.standardizedFileURL

        guard legacyURL.path != sourceURL.path,
              legacyURL.path != destinationURL.path,
              FileManager.default.fileExists(atPath: legacyURL.path)
        else {
            return
        }

        try FileManager.default.removeItem(at: legacyURL)
    }

    private static func complete(_ result: Result<Void, Error>, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

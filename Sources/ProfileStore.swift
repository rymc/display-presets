import Foundation

enum ProfileStore {
    private static var applicationSupportRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    static var supportDirectory: URL {
        applicationSupportRoot
            .appendingPathComponent(AppConstants.appName, isDirectory: true)
    }

    private static var legacySupportDirectory: URL {
        applicationSupportRoot
            .appendingPathComponent(AppConstants.legacyAppName, isDirectory: true)
    }

    static var profilesDirectory: URL {
        supportDirectory.appendingPathComponent("profiles", isDirectory: true)
    }

    static var orderFile: URL {
        supportDirectory.appendingPathComponent("order.txt")
    }

    static var stateFile: URL {
        supportDirectory.appendingPathComponent("state.txt")
    }

    private static var migrationMarkerFile: URL {
        supportDirectory.appendingPathComponent(".legacy-migration-complete")
    }

    static func ensureDirectories() {
        migrateLegacySupportIfNeeded()
        try? FileManager.default.createDirectory(
            at: profilesDirectory,
            withIntermediateDirectories: true
        )
    }

    static func loadProfilesByName() -> [String: Profile] {
        ensureDirectories()

        let files = (try? FileManager.default.contentsOfDirectory(
            at: profilesDirectory,
            includingPropertiesForKeys: nil
        )) ?? []

        var profilesByName: [String: Profile] = [:]

        for file in files where file.pathExtension == "profile" {
            let name = file.deletingPathExtension().lastPathComponent
            let arguments = loadArguments(from: file)

            if !arguments.isEmpty {
                profilesByName[name] = Profile(name: name, arguments: arguments)
            }
        }

        return profilesByName
    }

    static func profileExists(name: String) -> Bool {
        ensureDirectories()

        let normalizedName = safeName(name)
        let profileFile = profilesDirectory
            .appendingPathComponent(normalizedName)
            .appendingPathExtension("profile")

        return FileManager.default.fileExists(atPath: profileFile.path)
    }

    static func saveProfile(name: String, arguments: [String], allowOverwrite: Bool = false) throws {
        ensureDirectories()

        let normalizedName = safeName(name)
        let profileFile = profilesDirectory
            .appendingPathComponent(normalizedName)
            .appendingPathExtension("profile")

        if FileManager.default.fileExists(atPath: profileFile.path), !allowOverwrite {
            throw storeError("A preset named \(normalizedName) already exists.")
        }

        try writeLines(arguments, to: profileFile)

        var order = loadOrder()
        if !order.contains(normalizedName) {
            order.append(normalizedName)
            try writeLines(order, to: orderFile)
        }
    }

    static func deleteProfile(name: String) {
        let normalizedName = safeName(name)
        let profileFile = profilesDirectory
            .appendingPathComponent(normalizedName)
            .appendingPathExtension("profile")

        try? FileManager.default.removeItem(at: profileFile)

        let order = loadOrder().filter { $0 != normalizedName }
        try? writeLines(order, to: orderFile)

        if loadState() == normalizedName {
            try? FileManager.default.removeItem(at: stateFile)
        }
    }

    static func loadState() -> String? {
        guard let value = try? String(contentsOf: stateFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }

        return value
    }

    static func saveState(_ name: String) {
        ensureDirectories()
        try? "\(safeName(name))\n".write(to: stateFile, atomically: true, encoding: .utf8)
    }

    static func safeName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_."))
        let scalars = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let cleaned = String(scalars)
            .trimmingCharacters(in: CharacterSet(charactersIn: " -._"))
        return cleaned.isEmpty ? "Profile" : cleaned
    }

    private static func loadArguments(from file: URL) -> [String] {
        readLines(from: file)
    }

    static func loadOrder() -> [String] {
        readLines(from: orderFile)
    }

    private static func readLines(from file: URL) -> [String] {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else {
            return []
        }
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    private static func writeLines(_ lines: [String], to file: URL) throws {
        let text = lines.isEmpty ? "" : lines.joined(separator: "\n").appending("\n")
        try text.write(to: file, atomically: true, encoding: .utf8)
    }

    private static func migrateLegacySupportIfNeeded() {
        let fileManager = FileManager.default

        guard legacySupportDirectory.path != supportDirectory.path,
              fileManager.fileExists(atPath: legacySupportDirectory.path),
              !fileManager.fileExists(atPath: migrationMarkerFile.path)
        else {
            return
        }

        guard fileManager.fileExists(atPath: supportDirectory.path) else {
            do {
                try fileManager.moveItem(at: legacySupportDirectory, to: supportDirectory)
                try markLegacyMigrationComplete()
            } catch {
                return
            }
            return
        }

        do {
            try mergeLegacySupportFiles(with: fileManager)
            try markLegacyMigrationComplete()
        } catch {
            return
        }
    }

    private static func mergeLegacySupportFiles(with fileManager: FileManager) throws {
        let legacyProfilesDirectory = legacySupportDirectory.appendingPathComponent("profiles", isDirectory: true)
        try fileManager.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)

        let legacyProfiles = fileManager.fileExists(atPath: legacyProfilesDirectory.path)
            ? try fileManager.contentsOfDirectory(at: legacyProfilesDirectory, includingPropertiesForKeys: nil)
            : []

        for legacyProfile in legacyProfiles where legacyProfile.pathExtension == "profile" {
            let target = profilesDirectory.appendingPathComponent(legacyProfile.lastPathComponent)
            if !fileManager.fileExists(atPath: target.path) {
                try fileManager.copyItem(at: legacyProfile, to: target)
            }
        }

        try copyLegacyFileIfMissing(named: "order.txt", fileManager: fileManager)
        try copyLegacyFileIfMissing(named: "state.txt", fileManager: fileManager)
    }

    private static func copyLegacyFileIfMissing(named fileName: String, fileManager: FileManager) throws {
        let legacyFile = legacySupportDirectory.appendingPathComponent(fileName)
        let targetFile = supportDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: legacyFile.path),
           !fileManager.fileExists(atPath: targetFile.path) {
            try fileManager.copyItem(at: legacyFile, to: targetFile)
        }
    }

    private static func markLegacyMigrationComplete() throws {
        try FileManager.default.createDirectory(
            at: supportDirectory,
            withIntermediateDirectories: true
        )
        try "complete\n".write(to: migrationMarkerFile, atomically: true, encoding: .utf8)
    }

    private static func storeError(_ message: String) -> NSError {
        NSError(
            domain: AppConstants.appName,
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

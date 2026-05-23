import Darwin
import Foundation

enum DisplayplacerService {
    private static let applyTimeout: TimeInterval = 30
    private static let captureTimeout: TimeInterval = 10
    static let installCommand = "brew install displayplacer"
    static let missingDependencyMessage = "Install displayplacer with: \(installCommand)"

    static func apply(_ profile: Profile) throws {
        let result = try runDisplayplacer(
            arguments: profile.arguments,
            captureOutput: false,
            timeout: applyTimeout,
            timeoutMessage: "displayplacer timed out while applying the layout."
        )

        if result.terminationStatus != 0 {
            throw serviceError("displayplacer failed with exit code \(result.terminationStatus).")
        }
    }

    static func captureCurrentArguments() throws -> [String] {
        let result = try runDisplayplacer(
            arguments: ["list"],
            captureOutput: true,
            timeout: captureTimeout,
            timeoutMessage: "displayplacer timed out while reading the current layout."
        )

        guard result.terminationStatus == 0 else {
            throw serviceError("displayplacer failed with exit code \(result.terminationStatus).")
        }

        guard let text = String(data: result.output, encoding: .utf8),
              let commandLine = text.components(separatedBy: .newlines)
                .last(where: { $0.hasPrefix("displayplacer ") })
        else {
            throw serviceError("Could not capture the current layout.")
        }

        return parseDisplayplacerCommand(commandLine)
    }

    static func executablePath() -> String? {
        let candidates = [
            ProcessInfo.processInfo.environment["DISPLAYPLACER"],
            "/opt/homebrew/bin/displayplacer",
            "/usr/local/bin/displayplacer"
        ].compactMap { $0 }

        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func runDisplayplacer(
        arguments: [String],
        captureOutput: Bool,
        timeout: TimeInterval,
        timeoutMessage: String
    ) throws -> ProcessResult {
        guard let displayplacerPath = executablePath() else {
            throw serviceError(missingDependencyMessage)
        }

        let process = Process()
        let outputPipe = captureOutput ? Pipe() : nil
        let completed = DispatchSemaphore(value: 0)
        let outputReadGroup = DispatchGroup()
        let outputLock = NSLock()
        var capturedOutput = Data()

        if let outputPipe {
            outputReadGroup.enter()
            DispatchQueue.global(qos: .utility).async {
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                outputLock.lock()
                capturedOutput = data
                outputLock.unlock()
                outputReadGroup.leave()
            }
        }

        process.executableURL = URL(fileURLWithPath: displayplacerPath)
        process.arguments = arguments
        process.standardInput = nullFileHandle()
        process.standardOutput = outputPipe ?? nullFileHandle()
        process.standardError = nullFileHandle()
        process.terminationHandler = { _ in
            completed.signal()
        }

        try process.run()

        if completed.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()

            if completed.wait(timeout: .now() + 1) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = completed.wait(timeout: .now() + 1)
            }

            throw serviceError(timeoutMessage)
        }

        _ = outputReadGroup.wait(timeout: .now() + 1)
        outputLock.lock()
        let output = capturedOutput
        outputLock.unlock()
        return ProcessResult(output: output, terminationStatus: process.terminationStatus)
    }

    private static func parseDisplayplacerCommand(_ commandLine: String) -> [String] {
        let prefix = "displayplacer "
        let rawArguments = commandLine.hasPrefix(prefix)
            ? String(commandLine.dropFirst(prefix.count))
            : commandLine
        var arguments: [String] = []
        var current = ""
        var inQuotes = false
        var escaping = false

        for character in rawArguments {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }

            if character == "\\" {
                escaping = true
                continue
            }

            if character == "\"" {
                inQuotes.toggle()
                continue
            }

            if character == " " && !inQuotes {
                if !current.isEmpty {
                    arguments.append(current)
                    current = ""
                }
                continue
            }

            current.append(character)
        }

        if !current.isEmpty {
            arguments.append(current)
        }

        return arguments
    }

    private static func nullFileHandle() -> FileHandle {
        FileHandle.nullDevice
    }

    private static func serviceError(_ message: String) -> NSError {
        NSError(
            domain: AppConstants.appName,
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

private struct ProcessResult {
    let output: Data
    let terminationStatus: Int32
}

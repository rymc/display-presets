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
            timeout: applyTimeout,
            timeoutMessage: "displayplacer timed out while applying the layout."
        )

        if result.terminationStatus != 0 {
            throw serviceError(failureMessage("displayplacer failed", result: result))
        }
    }

    static func captureCurrentArguments() throws -> [String] {
        let result = try runDisplayplacer(
            arguments: ["list"],
            timeout: captureTimeout,
            timeoutMessage: "displayplacer timed out while reading the current layout."
        )

        guard result.terminationStatus == 0 else {
            throw serviceError(failureMessage("displayplacer list failed", result: result))
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
        timeout: TimeInterval,
        timeoutMessage: String
    ) throws -> ProcessResult {
        guard let displayplacerPath = executablePath() else {
            throw serviceError(missingDependencyMessage)
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let completed = DispatchSemaphore(value: 0)
        let outputReadGroup = DispatchGroup()
        let outputLock = NSLock()
        var capturedOutput = Data()
        var capturedErrorOutput = Data()

        captureData(from: outputPipe, group: outputReadGroup, lock: outputLock) {
            capturedOutput = $0
        }
        captureData(from: errorPipe, group: outputReadGroup, lock: outputLock) {
            capturedErrorOutput = $0
        }

        process.executableURL = URL(fileURLWithPath: displayplacerPath)
        process.arguments = arguments
        process.standardInput = nullFileHandle()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
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
        let errorOutput = capturedErrorOutput
        outputLock.unlock()
        return ProcessResult(output: output, errorOutput: errorOutput, terminationStatus: process.terminationStatus)
    }

    private static func captureData(
        from pipe: Pipe,
        group: DispatchGroup,
        lock: NSLock,
        assign: @escaping (Data) -> Void
    ) {
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            lock.lock()
            assign(data)
            lock.unlock()
            group.leave()
        }
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

    private static func failureMessage(_ prefix: String, result: ProcessResult) -> String {
        let lines = result.diagnosticText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { uniqueLines, line in
                if !uniqueLines.contains(line) {
                    uniqueLines.append(line)
                }
            }

        guard !lines.isEmpty else {
            return "\(prefix) with exit code \(result.terminationStatus)."
        }

        return "\(prefix): \(lines.prefix(2).joined(separator: " "))"
    }
}

private struct ProcessResult {
    let output: Data
    let errorOutput: Data
    let terminationStatus: Int32

    var diagnosticText: String {
        [output, errorOutput]
            .compactMap { String(data: $0, encoding: .utf8) }
            .joined(separator: "\n")
    }
}

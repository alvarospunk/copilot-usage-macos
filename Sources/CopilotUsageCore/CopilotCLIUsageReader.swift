import Foundation

public enum CopilotCLIUsageReader {
	public static func parsePercentage(from output: String) -> Int? {
		let value = output.trimmingCharacters(in: .whitespacesAndNewlines)
		guard value.hasSuffix("%"),
			  let percentage = Double(value.dropLast()),
			  percentage.isFinite,
			  (0...100).contains(percentage) else {
			return nil
		}
		return Int(percentage.rounded())
	}

	public static func readPercentage() throws -> Int {
		guard let scriptURL = Bundle.main.url(forResource: "usage-percent", withExtension: "sh") else {
			throw ReaderError.helperNotFound
		}
		let workingDirectory = Bundle.main.bundleURL
			.appendingPathComponent("Contents/Resources", isDirectory: true)
		guard FileManager.default.fileExists(atPath: workingDirectory.path) else {
			throw ReaderError.workingDirectoryNotFound
		}

		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/bin/sh")
		process.arguments = [scriptURL.path]
		process.currentDirectoryURL = workingDirectory
		var environment = ProcessInfo.processInfo.environment
		let home = FileManager.default.homeDirectoryForCurrentUser.path
		let additionalPaths = [
			"\(home)/.local/bin",
			"\(home)/.local/share/gh/copilot",
			"/opt/homebrew/bin",
			"/usr/local/bin",
		]
		environment["PATH"] = (additionalPaths + [environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"])
			.joined(separator: ":")
		process.environment = environment
		process.standardInput = FileHandle.nullDevice

		let outputPipe = Pipe()
		let errorPipe = Pipe()
		process.standardOutput = outputPipe
		process.standardError = errorPipe

		do {
			try process.run()
		} catch {
			throw ReaderError.couldNotStart(error.localizedDescription)
		}

		let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
		let errorOutput = errorPipe.fileHandleForReading.readDataToEndOfFile()
		process.waitUntilExit()

		guard process.terminationStatus == 0 else {
			let details = String(data: errorOutput, encoding: .utf8)?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw ReaderError.commandFailed(details)
		}
		guard let percentage = parsePercentage(from: String(data: output, encoding: .utf8) ?? "") else {
			throw ReaderError.invalidOutput
		}
		return percentage
	}
}

private enum ReaderError: LocalizedError {
	case helperNotFound
	case workingDirectoryNotFound
	case couldNotStart(String)
	case commandFailed(String)
	case invalidOutput

	var errorDescription: String? {
		switch self {
		case .helperNotFound:
			return "The bundled Copilot usage command could not be found. Rebuild Copilot Usage."
		case .workingDirectoryNotFound:
			return "The configured Copilot CLI working directory could not be found. Rebuild Copilot Usage."
		case .couldNotStart(let reason):
			return "Could not start the Copilot usage command: \(reason)"
		case .commandFailed(let details):
			return details.isEmpty ? "The Copilot usage command failed." : details
		case .invalidOutput:
			return "The Copilot usage command returned an invalid Plan percentage."
		}
	}
}

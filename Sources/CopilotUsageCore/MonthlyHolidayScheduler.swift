import Darwin
import Foundation

public enum MonthlyHolidayScheduler {
	public static let label = "com.jgarri.copilot-usage.monthly-holidays"

	public static func launchAgentConfiguration(appBundlePath: String) -> [String: Any] {
		let weekdayIntervals = (2...6).map { weekday in
			["Weekday": weekday, "Hour": 9, "Minute": 0]
		}
		return [
			"Label": label,
			"ProgramArguments": [
				"/usr/bin/open",
				"-n",
				"-W",
				appBundlePath,
				"--args",
				"--scheduled",
			],
			"StartCalendarInterval": weekdayIntervals,
			"RunAtLoad": false,
		]
	}

	public static func installIfNeeded(appBundlePath: String) throws {
		let launchAgentsDirectory = FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
		try FileManager.default.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)
		let plistURL = launchAgentsDirectory.appendingPathComponent("\(label).plist")
		let configuration = launchAgentConfiguration(appBundlePath: appBundlePath)
		let data = try PropertyListSerialization.data(fromPropertyList: configuration, format: .xml, options: 0)
		let existingData = try? Data(contentsOf: plistURL)
		let alreadyLoaded = launchctl(["print", "gui/\(getuid())/\(label)"]) == 0

		if existingData == data, alreadyLoaded {
			return
		}

		try data.write(to: plistURL, options: .atomic)
		_ = launchctl(["bootout", "gui/\(getuid())", plistURL.path])
		guard launchctl(["bootstrap", "gui/\(getuid())", plistURL.path]) == 0 else {
			throw SchedulerError.installFailed
		}
	}

	private static func launchctl(_ arguments: [String]) -> Int32 {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
		process.arguments = arguments
		process.standardOutput = FileHandle.nullDevice
		process.standardError = FileHandle.nullDevice
		do {
			try process.run()
			process.waitUntilExit()
			return process.terminationStatus
		} catch {
			return -1
		}
	}
}

private enum SchedulerError: LocalizedError {
	case installFailed

	var errorDescription: String? {
		"Could not install the monthly holiday reminder in the user's LaunchAgents."
	}
}

import Foundation

enum MonthlyHolidaySchedulerTest {
	static func run() {
		let configuration = MonthlyHolidayScheduler.launchAgentConfiguration(
			appBundlePath: "/Users/example/Applications/Copilot Usage.app"
		)
		let arguments = configuration["ProgramArguments"] as? [String] ?? []
		check(arguments == ["/usr/bin/open", "-n", "-W", "/Users/example/Applications/Copilot Usage.app", "--args", "--scheduled"], "LaunchAgent must open the installed app in scheduled mode.")

		let intervals = configuration["StartCalendarInterval"] as? [[String: Int]] ?? []
		let expected = (2...6).map { ["Weekday": $0, "Hour": 9, "Minute": 0] }
		check(intervals == expected, "LaunchAgent must check weekdays at 09:00 local time.")
		check(configuration["RunAtLoad"] as? Bool == false, "Installing the agent must not trigger a duplicate immediate prompt.")
	}

	private static func check(_ condition: Bool, _ message: String) {
		if !condition { fail(message) }
	}

	private static func fail(_ message: String) -> Never {
		fputs("Monthly scheduler test failed: \(message)\n", stderr)
		exit(1)
	}
}

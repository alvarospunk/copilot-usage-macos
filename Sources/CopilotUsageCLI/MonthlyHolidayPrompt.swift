import CopilotUsageCore
import Foundation

enum MonthlyHolidayPrompt {
	static func ask(
		monthDate: Date,
		suggestions: [HolidayDate],
		selectedDates: [HolidayDate]? = nil,
		calendar: Calendar = .current
	) -> [HolidayDate]? {
		let components = calendar.dateComponents([.year, .month], from: monthDate)
		guard let year = components.year, let month = components.month else { return nil }
		let monthName = DateFormatter()
		monthName.locale = Locale(identifier: "en_US_POSIX")
		monthName.calendar = calendar
		monthName.dateFormat = "MMMM yyyy"

		let monthSuggestions = (selectedDates ?? suggestions)
			.filter { $0.year == year && $0.month == month }
			.map(\.isoDate)
			.sorted()
		var currentInput = monthSuggestions.joined(separator: ", ")

		while true {
			let prompt = "Review the suggested national and Comunidad de Madrid holidays for \(monthName.string(from: monthDate)). Edit this comma-separated YYYY-MM-DD list to add Madrid city holidays or remove dates that are not days off."
			guard let input = displayInput(prompt: prompt, defaultAnswer: currentInput, title: "Madrid Holidays") else {
				return nil
			}
			currentInput = input

			do {
				return try HolidaySelection.parse(input, year: year, month: month)
			} catch {
				showError(error.localizedDescription)
			}
		}
	}

	private static func displayInput(prompt: String, defaultAnswer: String, title: String) -> String? {
		let script = """
		set result to display dialog \(appleScriptString(prompt)) with title \(appleScriptString(title)) default answer \(appleScriptString(defaultAnswer)) buttons {"Cancel", "Save"} default button "Save" cancel button "Cancel"
		return text returned of result
		"""
		return runAppleScript(script)
	}

	private static func showError(_ message: String) {
		let script = "display dialog \(appleScriptString(message)) with title \"Invalid Holiday Date\" buttons {\"OK\"} default button \"OK\""
		_ = runAppleScript(script)
	}

	private static func runAppleScript(_ script: String) -> String? {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
		process.arguments = ["-e", script]
		let output = Pipe()
		process.standardOutput = output
		process.standardError = FileHandle.nullDevice
		do {
			try process.run()
			let data = output.fileHandleForReading.readDataToEndOfFile()
			process.waitUntilExit()
			guard process.terminationStatus == 0 else { return nil }
			return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
		} catch {
			return nil
		}
	}

	private static func appleScriptString(_ value: String) -> String {
		let escaped = value
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\"", with: "\\\"")
		return "\"\(escaped)\""
	}
}

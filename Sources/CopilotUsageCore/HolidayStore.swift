import Foundation

public struct HolidayStore {
	private struct State: Codable {
		var holidaysByMonth: [String: [String]] = [:]
	}

	private let fileURL: URL

	public init(fileURL: URL? = nil) {
		if let fileURL {
			self.fileURL = fileURL
		} else {
			let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
			self.fileURL = applicationSupport
				.appendingPathComponent("com.jgarri.copilot-usage", isDirectory: true)
				.appendingPathComponent("holidays.json")
		}
	}

	public func load(month: String) throws -> [HolidayDate]? {
		guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
		let state = try JSONDecoder().decode(State.self, from: Data(contentsOf: fileURL))
		guard let dates = state.holidaysByMonth[month] else { return nil }
		return try dates.map { value in
			guard let date = HolidayDate(isoDate: value) else {
				throw HolidaySelectionError.invalidDate(value)
			}
			return date
		}
	}

	public func save(month: String, holidays: [HolidayDate]) throws {
		var state: State
		if FileManager.default.fileExists(atPath: fileURL.path) {
			state = try JSONDecoder().decode(State.self, from: Data(contentsOf: fileURL))
		} else {
			state = State()
		}

		let monthPrefix = "\(month)-"
		guard holidays.allSatisfy({ $0.isoDate.hasPrefix(monthPrefix) }) else {
			throw HolidaySelectionError.dateOutsideMonth(holidays.first(where: { !$0.isoDate.hasPrefix(monthPrefix) })?.isoDate ?? "unknown")
		}

		state.holidaysByMonth[month] = Array(Set(holidays.map(\.isoDate))).sorted()
		let directory = fileURL.deletingLastPathComponent()
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		try encoder.encode(state).write(to: fileURL, options: .atomic)
	}
}

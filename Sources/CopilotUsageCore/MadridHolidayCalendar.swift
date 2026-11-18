import Foundation

public enum MadridHolidayCalendar {
	private struct Entry: Decodable {
		let date: String
		let global: Bool
		let counties: [String]?
	}

	public static func suggestions(from data: Data, year: Int) throws -> [HolidayDate] {
		let entries = try JSONDecoder().decode([Entry].self, from: data)
		let dates = entries.compactMap { entry -> HolidayDate? in
			guard entry.global || entry.counties?.contains("ES-MD") == true,
				  let holiday = HolidayDate(isoDate: entry.date),
				  holiday.year == year else {
				return nil
			}
			return holiday
		}
		return Array(Set(dates)).sorted { $0.isoDate < $1.isoDate }
	}

	public static func fetchSuggestions(year: Int, session: URLSession = .shared) async throws -> [HolidayDate] {
		guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/ES") else {
			throw HolidayCalendarError.invalidURL
		}
		var request = URLRequest(url: url)
		request.timeoutInterval = 5
		let (data, response) = try await session.data(for: request)
		guard let response = response as? HTTPURLResponse,
			  (200..<300).contains(response.statusCode) else {
			throw HolidayCalendarError.invalidResponse
		}
		return try suggestions(from: data, year: year)
	}
}

public enum HolidaySelectionError: LocalizedError {
	case invalidDate(String)
	case dateOutsideMonth(String)

	public var errorDescription: String? {
		switch self {
		case .invalidDate(let value):
			return "Invalid holiday date: \(value). Use YYYY-MM-DD."
		case .dateOutsideMonth(let value):
			return "Holiday date \(value) is outside the selected month."
		}
	}
}

public enum HolidaySelection {
	public static func parse(_ input: String, year: Int, month: Int) throws -> [HolidayDate] {
		let tokens = input.split { character in
			character == "," || character == ";" || character.isWhitespace
		}
		var dates: Set<HolidayDate> = []
		for token in tokens {
			let value = String(token)
			guard let holiday = HolidayDate(isoDate: value) else {
				throw HolidaySelectionError.invalidDate(value)
			}
			guard holiday.year == year, holiday.month == month else {
				throw HolidaySelectionError.dateOutsideMonth(value)
			}
			dates.insert(holiday)
		}
		return dates.sorted { $0.isoDate < $1.isoDate }
	}
}

private enum HolidayCalendarError: LocalizedError {
	case invalidURL
	case invalidResponse

	var errorDescription: String? {
		switch self {
		case .invalidURL:
			return "Could not construct the Madrid holiday calendar URL."
		case .invalidResponse:
			return "The Madrid holiday calendar service returned an invalid response."
		}
	}
}

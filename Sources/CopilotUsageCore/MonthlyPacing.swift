import Foundation

public struct HolidayDate: Hashable, Codable, CustomStringConvertible {
	public let isoDate: String

	public init?(isoDate: String) {
		let components = isoDate.split(separator: "-", omittingEmptySubsequences: false)
		guard components.count == 3,
			  components[0].count == 4,
			  components[1].count == 2,
			  components[2].count == 2,
			  components.allSatisfy({ $0.allSatisfy(\.isNumber) }),
			  let year = Int(components[0]),
			  let month = Int(components[1]),
			  let day = Int(components[2]) else {
			return nil
		}

		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!
		let dateComponents = DateComponents(year: year, month: month, day: day)
		guard let date = calendar.date(from: dateComponents) else { return nil }
		let validated = calendar.dateComponents([.year, .month, .day], from: date)
		guard validated.year == year, validated.month == month, validated.day == day else {
			return nil
		}

		self.isoDate = isoDate
	}

	public var year: Int { Int(isoDate.prefix(4))! }
	public var month: Int { Int(isoDate.dropFirst(5).prefix(2))! }
	public var day: Int { Int(isoDate.suffix(2))! }
	public var description: String { isoDate }
}

public struct MonthlyPacingSummary: Equatable {
	public let totalWorkDays: Int
	public let elapsedWorkDays: Int
	public let futureWorkDays: Int
	public let expectedUsagePercent: Double
	public let variancePercentagePoints: Double
	public let remainingAveragePercentPerWorkDay: Double
}

public enum MonthlyPacing {
	public static func firstWorkDay(
		year: Int,
		month: Int,
		holidays: Set<HolidayDate>,
		calendar: Calendar = .current
	) -> Date? {
		workDays(year: year, month: month, holidays: holidays, calendar: calendar).first
	}

	public static func isEligibleToPrompt(
		today: Date,
		holidays: Set<HolidayDate>,
		calendar: Calendar = .current
	) -> Bool {
		let todayComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: today)
		guard let year = todayComponents.year,
			  let month = todayComponents.month,
			  let weekday = todayComponents.weekday,
			  (2...6).contains(weekday),
			  let todayKey = isoDate(year: year, month: month, day: todayComponents.day!) else {
			return false
		}

		guard !holidays.contains(where: { $0.isoDate == todayKey }),
			  let firstWorkDay = firstWorkDay(year: year, month: month, holidays: holidays, calendar: calendar) else {
			return false
		}
		return calendar.startOfDay(for: today) >= calendar.startOfDay(for: firstWorkDay)
	}

	public static func summary(
		year: Int,
		month: Int,
		today: Date,
		holidays: Set<HolidayDate>,
		usedPercent: Int,
		calendar: Calendar = .current
	) -> MonthlyPacingSummary? {
		let days = workDays(year: year, month: month, holidays: holidays, calendar: calendar)
		guard !days.isEmpty else { return nil }

		let todayStart = calendar.startOfDay(for: today)
		let elapsed = days.filter { calendar.startOfDay(for: $0) <= todayStart }.count
		let future = days.count - elapsed
		let expected = Double(elapsed) / Double(days.count) * 100
		let remaining = future > 0 ? max(0, 100 - Double(usedPercent)) / Double(future) : 0

		return MonthlyPacingSummary(
			totalWorkDays: days.count,
			elapsedWorkDays: elapsed,
			futureWorkDays: future,
			expectedUsagePercent: expected,
			variancePercentagePoints: Double(usedPercent) - expected,
			remainingAveragePercentPerWorkDay: remaining
		)
	}

	private static func workDays(
		year: Int,
		month: Int,
		holidays: Set<HolidayDate>,
		calendar: Calendar
	) -> [Date] {
		guard (1...12).contains(month),
			  let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
			  let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
			return []
		}

		return dayRange.compactMap { day in
			guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { return nil }
			let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
			guard let weekday = components.weekday,
				  (2...6).contains(weekday),
				  let dateKey = isoDate(year: year, month: month, day: day),
				  !holidays.contains(where: { $0.isoDate == dateKey }) else {
				return nil
			}
			return date
		}
	}

	private static func isoDate(year: Int, month: Int, day: Int?) -> String? {
		guard let day else { return nil }
		return String(format: "%04d-%02d-%02d", year, month, day)
	}
}

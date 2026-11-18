import Foundation

enum MonthlyPacingTest {
	static func run() {
		let calendar = testCalendar()
		guard let holiday = HolidayDate(isoDate: "2026-11-11") else {
			fail("Valid holiday date was rejected.")
		}
		guard HolidayDate(isoDate: "2026-02-30") == nil,
			  HolidayDate(isoDate: "2026-2-3") == nil else {
			fail("Invalid holiday dates were accepted.")
		}

		let holidays: Set<HolidayDate> = [holiday]
		guard let summary = MonthlyPacing.summary(
			year: 2026,
			month: 11,
			today: date(2026, 11, 10, calendar: calendar),
			holidays: holidays,
			usedPercent: 25,
			calendar: calendar
		) else {
			fail("Monthly pacing summary was not produced.")
		}

		check(summary.totalWorkDays == 20, "Expected the holiday to reduce November's workdays to 20.")
		check(summary.elapsedWorkDays == 7, "Expected 7 elapsed workdays through November 10.")
		check(summary.futureWorkDays == 13, "Expected 13 future workdays after November 10.")
		check(summary.expectedUsagePercent == 35, "Expected usage pace to be 35% on November 10.")
		check(summary.variancePercentagePoints == -10, "Expected actual usage to be 10 points below pace.")
		check(
			abs(summary.remainingAveragePercentPerWorkDay - (75.0 / 13.0)) < 0.0001,
			"Expected the unused 75% to be split across 13 future workdays."
		)

		let nov2 = date(2026, 11, 2, calendar: calendar)
		let nov3 = date(2026, 11, 3, calendar: calendar)
		let holidaysWithFirstWeekday: Set<HolidayDate> = [HolidayDate(isoDate: "2026-11-02")!]
		check(
			!MonthlyPacing.isEligibleToPrompt(today: nov2, holidays: holidaysWithFirstWeekday, calendar: calendar),
			"A saved holiday must not be eligible for the monthly prompt."
		)
		check(
			MonthlyPacing.isEligibleToPrompt(today: nov3, holidays: holidaysWithFirstWeekday, calendar: calendar),
			"The first non-holiday weekday must be eligible for the monthly prompt."
		)
		check(
			MonthlyPacing.isEligibleToPrompt(today: date(2026, 11, 4, calendar: calendar), holidays: holidaysWithFirstWeekday, calendar: calendar),
			"An unconfigured month must catch up after the first workday was missed."
		)
	}

	private static func testCalendar() -> Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0)!
		return calendar
	}

	private static func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
		calendar.date(from: DateComponents(year: year, month: month, day: day))!
	}

	private static func check(_ condition: Bool, _ message: String) {
		if !condition {
			fail(message)
		}
	}

	private static func fail(_ message: String) -> Never {
		fputs("Monthly pacing test failed: \(message)\n", stderr)
		exit(1)
	}
}

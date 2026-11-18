import Foundation

enum HolidayCalendarTest {
	static func run() {
		testMadridSuggestions()
		testManualDatesAreRestrictedToMonth()
		testHolidayStoreDistinguishesUnconfiguredAndEmpty()
	}

	private static func testMadridSuggestions() {
		let response = """
		[
		  {"date":"2026-01-01","global":true,"counties":null},
		  {"date":"2026-05-02","global":false,"counties":["ES-MD"]},
		  {"date":"2026-05-30","global":false,"counties":["ES-CN"]},
		  {"date":"2026-11-11","global":false,"counties":null}
		]
		"""
		do {
			let dates = try MadridHolidayCalendar.suggestions(from: Data(response.utf8), year: 2026)
			check(dates.map(\.isoDate) == ["2026-01-01", "2026-05-02"], "Only national and Madrid-region dates should be suggested.")
		} catch {
			fail("Madrid holiday response could not be decoded: \(error)")
		}
	}

	private static func testManualDatesAreRestrictedToMonth() {
		do {
			let dates = try HolidaySelection.parse("2026-11-09, 2026-11-11", year: 2026, month: 11)
			check(dates.map(\.isoDate) == ["2026-11-09", "2026-11-11"], "Valid November holiday dates should be retained.")
		} catch {
			fail("Valid manual holiday dates were rejected: \(error)")
		}

		do {
			_ = try HolidaySelection.parse("2026-10-12", year: 2026, month: 11)
			fail("A holiday from another month was accepted.")
		} catch HolidaySelectionError.dateOutsideMonth {
		} catch {
			fail("Unexpected error for out-of-month holiday: \(error)")
		}
	}

	private static func testHolidayStoreDistinguishesUnconfiguredAndEmpty() {
		let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		let store = HolidayStore(fileURL: directory.appendingPathComponent("holidays.json"))
		defer { try? FileManager.default.removeItem(at: directory) }

		do {
			check(try store.load(month: "2026-11") == nil, "Missing month must be unconfigured.")
			try store.save(month: "2026-11", holidays: [])
			check(try store.load(month: "2026-11") == [], "An empty list must still mark the month configured.")
			let dates = [HolidayDate(isoDate: "2026-11-11")!]
			try store.save(month: "2026-11", holidays: dates)
			check(try store.load(month: "2026-11") == dates, "Saved manual dates must round-trip.")
		} catch {
			fail("Holiday store failed: \(error)")
		}
	}

	private static func check(_ condition: Bool, _ message: String) {
		if !condition { fail(message) }
	}

	private static func fail(_ message: String) -> Never {
		fputs("Holiday calendar test failed: \(message)\n", stderr)
		exit(1)
	}
}

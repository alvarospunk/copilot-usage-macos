import Foundation

enum UsageMenuPresentationTest {
	static func run() {
		let summary = MonthlyPacingSummary(
			totalWorkDays: 19,
			elapsedWorkDays: 6,
			futureWorkDays: 13,
			expectedUsagePercent: 31.6,
			variancePercentagePoints: -6.6,
			remainingAveragePercentPerWorkDay: 75.0 / 13.0
		)
		let presentation = UsageMenuPresentation.make(usedPercent: 25, summary: summary)
		let hideTarget = UsageMenuPresentation.make(usedPercent: 25, summary: summary, hideTargetDailyUsage: true)
		let hideCurrent = UsageMenuPresentation.make(usedPercent: 25, summary: summary, hideCurrentUsage: true)
		let hideBoth = UsageMenuPresentation.make(usedPercent: 25, summary: summary, hideCurrentUsage: true, hideTargetDailyUsage: true)

		check(presentation.statusTitle == "🐸 25% / 31.6%", "The menu-bar item should show current usage and today's expected limit.")
		check(hideTarget.statusTitle == "🐸 25%", "Hiding the target should leave current usage in the menu bar.")
		check(hideCurrent.statusTitle == "🐸 31.6%", "Hiding current usage should leave today's target in the menu bar.")
		check(hideBoth.statusTitle == "🐸", "Hiding both values should leave only the frog in the menu bar.")
		check(presentation.actualText == "25% used", "The popover should display current usage.")
		check(presentation.expectedText == "Today you can spend until 31.6%", "The popover should display the clear spend threshold for today.")
		check(presentation.dailyBudgetText == "5.77% per working day", "The popover should display remaining daily allowance.")
		check(presentation.daysRemainingText == "13 working days left", "The popover should display remaining workdays.")
	}

	private static func check(_ condition: Bool, _ message: String) {
		if !condition {
			fputs("Usage menu presentation test failed: \(message)\n", stderr)
			exit(1)
		}
	}
}

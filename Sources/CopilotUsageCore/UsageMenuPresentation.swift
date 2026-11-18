import Foundation

public struct UsageMenuPresentation: Equatable {
	public let statusTitle: String
	public let actualText: String
	public let expectedText: String
	public let dailyBudgetText: String
	public let daysRemainingText: String

	public static func make(
		usedPercent: Int,
		summary: MonthlyPacingSummary,
		hideCurrentUsage: Bool = false,
		hideTargetDailyUsage: Bool = false
	) -> UsageMenuPresentation {
		let expectedUsage = String(format: "%.1f%%", locale: Locale(identifier: "en_US_POSIX"), summary.expectedUsagePercent)
	var statusValues: [String] = []
	if !hideCurrentUsage { statusValues.append("\(usedPercent)%") }
	if !hideTargetDailyUsage { statusValues.append(expectedUsage) }
	let statusSuffix = statusValues.isEmpty ? "" : " \(statusValues.joined(separator: " / "))"
		return UsageMenuPresentation(
			statusTitle: "🐸\(statusSuffix)",
			actualText: "\(usedPercent)% used",
			expectedText: "Today you can spend until \(expectedUsage)",
			dailyBudgetText: String(format: "%.2f%% per working day", locale: Locale(identifier: "en_US_POSIX"), summary.remainingAveragePercentPerWorkDay),
			daysRemainingText: "\(summary.futureWorkDays) working days left"
		)
	}
}

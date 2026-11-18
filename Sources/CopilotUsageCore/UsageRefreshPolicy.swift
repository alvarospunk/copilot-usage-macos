import Foundation

public enum UsageRefreshTrigger {
	case manual
	case automatic
	case forced
}

public enum UsageRefreshPolicy {
	public static let minimumInterval: TimeInterval = 60
	public static let automaticInterval: TimeInterval = 60
	public static let supportedMinutes = [1, 5, 15, 30, 60]

	public static func validatedMinutes(_ minutes: Int) -> Int {
		supportedMinutes.contains(minutes) ? minutes : 1
	}

	public static func shouldRefresh(
		lastSuccessfulAt: Date?,
		lastAttemptAt: Date?,
		now: Date,
		trigger: UsageRefreshTrigger,
		interval: TimeInterval = automaticInterval
	) -> Bool {
		if trigger == .forced { return true }
		if trigger == .manual, let lastSuccessfulAt {
			let elapsedSinceSuccess = now.timeIntervalSince(lastSuccessfulAt)
			if elapsedSinceSuccess < interval { return false }
		}

		guard trigger == .automatic, let lastAttemptAt else { return true }
		return now.timeIntervalSince(lastAttemptAt) >= interval
	}
}

extension UsageRefreshTrigger: Equatable {}

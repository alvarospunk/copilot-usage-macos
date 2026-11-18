import Foundation

enum UsageRefreshPolicyTest {
	static func run() {
		let now = Date(timeIntervalSince1970: 1_800_000_000)
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: nil, lastAttemptAt: nil, now: now, trigger: .automatic),
			"The app should check usage when no cached reading exists."
		)
		check(
			!UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: now.addingTimeInterval(-30), lastAttemptAt: now.addingTimeInterval(-30), now: now, trigger: .manual),
			"Opening the popover should reuse a reading younger than one minute."
		)
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: now.addingTimeInterval(-60), lastAttemptAt: now.addingTimeInterval(-60), now: now, trigger: .manual),
			"Opening the popover should recheck after one minute."
		)
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: nil, lastAttemptAt: now.addingTimeInterval(-60), now: now, trigger: .manual),
			"A failed attempt must not block a manual retry."
		)
		check(
			!UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: nil, lastAttemptAt: now.addingTimeInterval(-59), now: now, trigger: .automatic),
			"Automatic refresh must wait for one minute."
		)
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: nil, lastAttemptAt: now.addingTimeInterval(-60), now: now, trigger: .automatic),
			"Automatic refresh should run once a minute has elapsed."
		)
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: now, lastAttemptAt: now, now: now, trigger: .forced),
			"The refresh button must bypass the cache."
		)
		check(
			!UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: nil, lastAttemptAt: now.addingTimeInterval(-60), now: now, trigger: .automatic, interval: 300),
			"A custom five-minute frequency must be respected."
		)
		check(UsageRefreshPolicy.validatedMinutes(0) == 1, "Missing frequency must default to one minute.")
		check(UsageRefreshPolicy.validatedMinutes(15) == 15, "Supported frequency must be retained.")
		check(
			UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: now.addingTimeInterval(-55), lastAttemptAt: now.addingTimeInterval(-60), now: now, trigger: .automatic),
			"CLI execution time must not skip the next scheduled minute."
		)
		check(
			!UsageRefreshPolicy.shouldRefresh(lastSuccessfulAt: now.addingTimeInterval(60), lastAttemptAt: nil, now: now, trigger: .manual),
			"Clock skew must not trigger an early refresh."
		)
	}

	private static func check(_ condition: Bool, _ message: String) {
		if !condition {
			fputs("Usage refresh policy test failed: \(message)\n", stderr)
			exit(1)
		}
	}
}

import AppKit
import CopilotUsageCore
import Foundation

@MainActor
final class CopilotUsageMenuBarApp: NSObject, NSApplicationDelegate {
	private let store = HolidayStore()
	private let defaults = UserDefaults.standard
	private let popover = NSPopover()
	private let contentController = UsagePopoverViewController()
	private var statusItem: NSStatusItem!
	private var isRefreshing = false
	private var refreshTimer: Timer?

	private enum CacheKey {
		static let lastAttemptAt = "usage.lastAttemptAt"
		static let lastSuccessAt = "usage.lastSuccessAt"
		static let lastUsedPercent = "usage.lastUsedPercent"
		static let updateFrequencyMinutes = "usage.updateFrequencyMinutes"
		static let hideCurrentUsage = "usage.hideCurrentUsage"
		static let hideTargetDailyUsage = "usage.hideTargetDailyUsage"
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.setActivationPolicy(.accessory)
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusItem.button?.title = "🐸"
		statusItem.button?.isEnabled = true
		statusItem.button?.toolTip = "Copilot usage"
		statusItem.button?.target = self
		statusItem.button?.action = #selector(togglePopover)

		contentController.onRefresh = { [weak self] in
			self?.refreshUsage(trigger: .forced, presentPopover: true)
		}
		contentController.onEditHolidays = { [weak self] in self?.editHolidays() }
		contentController.onUpdateFrequency = { [weak self] in self?.editUpdateFrequency() }
		contentController.onVisibilityOptionsChanged = { [weak self] hideCurrentUsage, hideTargetDailyUsage in
			guard let self else { return }
			self.defaults.set(hideCurrentUsage, forKey: CacheKey.hideCurrentUsage)
			self.defaults.set(hideTargetDailyUsage, forKey: CacheKey.hideTargetDailyUsage)
			self.displayCachedReading(now: Date())
		}
		contentController.onStatusTitle = { [weak self] title in
			self?.statusItem.button?.title = title
			self?.statusItem.button?.isEnabled = true
		}
		popover.contentViewController = contentController
		contentController.setVisibilityOptions(
			hideCurrentUsage: defaults.bool(forKey: CacheKey.hideCurrentUsage),
			hideTargetDailyUsage: defaults.bool(forKey: CacheKey.hideTargetDailyUsage)
		)
		popover.behavior = .transient
		popover.contentSize = NSSize(width: 350, height: 320)

		displayCachedReading(now: Date())
		scheduleRefreshTimer()
		refreshUsage(trigger: .automatic, presentPopover: false)
	}

	private var updateInterval: TimeInterval {
		TimeInterval(UsageRefreshPolicy.validatedMinutes(defaults.integer(forKey: CacheKey.updateFrequencyMinutes)) * 60)
	}

	private func scheduleRefreshTimer() {
		refreshTimer?.invalidate()
		refreshTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
			Task { @MainActor in
				self?.refreshUsage(trigger: .automatic, presentPopover: false)
			}
		}
	}

	private func editUpdateFrequency() {
		let selector = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 220, height: 28))
		selector.addItems(withTitles: UsageRefreshPolicy.supportedMinutes.map { $0 == 1 ? "1 minute" : "\($0) minutes" })
		let current = UsageRefreshPolicy.validatedMinutes(defaults.integer(forKey: CacheKey.updateFrequencyMinutes))
		selector.selectItem(at: UsageRefreshPolicy.supportedMinutes.firstIndex(of: current) ?? 0)
		let alert = NSAlert()
		alert.messageText = "Update frequency"
		alert.accessoryView = selector
		alert.addButton(withTitle: "Save")
		alert.addButton(withTitle: "Cancel")
		guard alert.runModal() == .alertFirstButtonReturn else { return }
		defaults.set(UsageRefreshPolicy.supportedMinutes[selector.indexOfSelectedItem], forKey: CacheKey.updateFrequencyMinutes)
		scheduleRefreshTimer()
		refreshUsage(trigger: .forced, presentPopover: true)
	}

	@objc private func togglePopover() {
		guard let button = statusItem.button else { return }
		button.isEnabled = true
		if popover.isShown {
			popover.performClose(nil)
		} else {
			NSApp.activate(ignoringOtherApps: true)
			popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
			button.highlight(false)
			refreshUsage(trigger: .manual, presentPopover: true)
		}
	}

	private func refreshUsage(trigger: UsageRefreshTrigger, presentPopover: Bool) {
		guard !isRefreshing else { return }
		let now = Date()
		let lastAttemptAt = defaults.object(forKey: CacheKey.lastAttemptAt) as? Date
		let lastSuccessfulAt = defaults.object(forKey: CacheKey.lastSuccessAt) as? Date
		guard UsageRefreshPolicy.shouldRefresh(
			lastSuccessfulAt: lastSuccessfulAt,
			lastAttemptAt: lastAttemptAt,
			now: now,
			trigger: trigger,
			interval: updateInterval
		) else {
			displayCachedReading(now: now)
			if presentPopover || popover.isShown {
				NSApp.activate(ignoringOtherApps: true)
				showPopover()
			}
			return
		}

		defaults.set(now, forKey: CacheKey.lastAttemptAt)
		isRefreshing = true
		if presentPopover || popover.isShown {
			contentController.showLoading()
		}
		Task { @MainActor in
			defer { self.isRefreshing = false }
			do {
				let now = Date()
				let calendar = Calendar.current
				let components = calendar.dateComponents([.year, .month], from: now)
				guard let year = components.year, let month = components.month else {
					throw MenuBarError.couldNotDetermineMonth
				}
				let monthKey = String(format: "%04d-%02d", year, month)
				let holidays = try await holidaysForCurrentMonth(now, year: year, month: month, monthKey: monthKey, calendar: calendar)
				let usedPercent = try await Task.detached {
					try CopilotCLIUsageReader.readPercentage()
				}.value
				let checkedAt = Date()
				defaults.set(usedPercent, forKey: CacheKey.lastUsedPercent)
				defaults.set(checkedAt, forKey: CacheKey.lastSuccessAt)
				guard let summary = MonthlyPacing.summary(
					year: year,
					month: month,
					today: now,
					holidays: Set(holidays),
					usedPercent: usedPercent,
					calendar: calendar
				) else {
					contentController.showMessage("No working days are configured for this month.")
					return
				}
				contentController.show(
					UsageMenuPresentation.make(
						usedPercent: usedPercent,
						summary: summary,
						hideCurrentUsage: defaults.bool(forKey: CacheKey.hideCurrentUsage),
						hideTargetDailyUsage: defaults.bool(forKey: CacheKey.hideTargetDailyUsage)
					),
					checkedAt: checkedAt
				)
				if presentPopover || popover.isShown {
					NSApp.activate(ignoringOtherApps: true)
					showPopover()
				}
			} catch {
				if presentPopover || popover.isShown {
					contentController.showMessage(error.localizedDescription)
					NSApp.activate(ignoringOtherApps: true)
					showPopover()
				}
			}
		}
	}

	private func displayCachedReading(now: Date) {
		guard let usedPercent = defaults.object(forKey: CacheKey.lastUsedPercent) as? Int,
			  let checkedAt = defaults.object(forKey: CacheKey.lastSuccessAt) as? Date else {
			return
		}
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month], from: now)
		guard let year = components.year, let month = components.month else { return }
		let monthKey = String(format: "%04d-%02d", year, month)
		guard let savedHolidays = try? store.load(month: monthKey),
			  let summary = MonthlyPacing.summary(
				year: year,
				month: month,
				today: now,
				holidays: Set(savedHolidays),
				usedPercent: usedPercent,
				calendar: calendar
			  ) else {
			return
		}
		contentController.show(
			UsageMenuPresentation.make(
				usedPercent: usedPercent,
				summary: summary,
				hideCurrentUsage: defaults.bool(forKey: CacheKey.hideCurrentUsage),
				hideTargetDailyUsage: defaults.bool(forKey: CacheKey.hideTargetDailyUsage)
			),
			checkedAt: checkedAt
		)
	}

	private func editHolidays() {
		Task { @MainActor in
			do {
				let now = Date()
				let calendar = Calendar.current
				let components = calendar.dateComponents([.year, .month], from: now)
				guard let year = components.year, let month = components.month else {
					throw MenuBarError.couldNotDetermineMonth
				}
				let monthKey = String(format: "%04d-%02d", year, month)
				let current = try store.load(month: monthKey)
				let suggestions = await fetchHolidaySuggestions(year: year, month: month)
				guard let selected = MonthlyHolidayPrompt.ask(
					monthDate: now,
					suggestions: suggestions,
					selectedDates: current,
					calendar: calendar
				) else { return }
				try store.save(month: monthKey, holidays: selected)
				displayCachedReading(now: now)
				refreshUsage(trigger: .manual, presentPopover: true)
			} catch {
				contentController.showMessage(error.localizedDescription)
			}
		}
	}

	private func holidaysForCurrentMonth(
		_ now: Date,
		year: Int,
		month: Int,
		monthKey: String,
		calendar: Calendar
	) async throws -> [HolidayDate] {
		if let saved = try store.load(month: monthKey) { return saved }
		let suggestions = await fetchHolidaySuggestions(year: year, month: month)
		guard MonthlyPacing.isEligibleToPrompt(today: now, holidays: Set(suggestions), calendar: calendar) else {
			return []
		}
		guard let selected = MonthlyHolidayPrompt.ask(monthDate: now, suggestions: suggestions, calendar: calendar) else {
			throw MenuBarError.holidaySetupCancelled
		}
		try store.save(month: monthKey, holidays: selected)
		return selected
	}

	private func fetchHolidaySuggestions(year: Int, month: Int) async -> [HolidayDate] {
		(try? await MadridHolidayCalendar.fetchSuggestions(year: year).filter { $0.month == month }) ?? []
	}

	private func showPopover() {
		guard let button = statusItem.button else { return }
		if !popover.isShown {
			popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
		}
		button.isEnabled = true
		button.highlight(false)
	}
}

private enum MenuBarError: LocalizedError {
	case couldNotDetermineMonth
	case holidaySetupCancelled

	var errorDescription: String? {
		switch self {
		case .couldNotDetermineMonth:
			return "Could not determine the current month."
		case .holidaySetupCancelled:
			return "Holiday setup was cancelled. Use Edit Holidays to try again."
		}
	}
}

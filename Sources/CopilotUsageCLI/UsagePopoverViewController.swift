import AppKit
import CopilotUsageCore

@MainActor
final class UsagePopoverViewController: NSViewController {
	var onRefresh: (() -> Void)?
	var onEditHolidays: (() -> Void)?
	var onUpdateFrequency: (() -> Void)?
	var onVisibilityOptionsChanged: ((Bool, Bool) -> Void)?
	var onStatusTitle: ((String) -> Void)?

	private let actualLabel = NSTextField(labelWithString: "Not checked")
	private let expectedLabel = NSTextField(labelWithString: "Today you can spend until --%")
	private let dailyBudgetLabel = NSTextField(labelWithString: "--% per working day")
	private let daysRemainingLabel = NSTextField(labelWithString: "-- working days left")
	private let updatedLabel = NSTextField(labelWithString: "Not checked yet")
	private let messageLabel = NSTextField(wrappingLabelWithString: "")
	private let hideCurrentUsageCheckbox = NSButton(checkboxWithTitle: "Hide current usage", target: nil, action: nil)
	private let hideTargetDailyUsageCheckbox = NSButton(checkboxWithTitle: "Hide target daily usage", target: nil, action: nil)

	override func loadView() {
		let root = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 320))
		let titleLabel = NSTextField(labelWithString: "Copilot Credits")
		titleLabel.font = .boldSystemFont(ofSize: 15)

		actualLabel.font = .systemFont(ofSize: 24, weight: .semibold)
		daysRemainingLabel.textColor = .secondaryLabelColor
		messageLabel.textColor = .secondaryLabelColor
		updatedLabel.textColor = .secondaryLabelColor
		updatedLabel.font = .systemFont(ofSize: 11)

		let refreshButton = NSButton(
			image: NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh Copilot usage")!,
			target: self,
			action: #selector(refreshClicked)
		)
		refreshButton.bezelStyle = .toolbar
		refreshButton.imageScaling = .scaleProportionallyDown
		refreshButton.setAccessibilityLabel("Refresh Copilot usage")
		refreshButton.toolTip = "Refresh Copilot usage"
		refreshButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
		refreshButton.heightAnchor.constraint(equalToConstant: 30).isActive = true

		let editButton = NSButton(title: "Edit Holidays", target: self, action: #selector(editHolidaysClicked))
		editButton.bezelStyle = .rounded
		let frequencyButton = NSButton(title: "Update frequency", target: self, action: #selector(updateFrequencyClicked))
		frequencyButton.bezelStyle = .rounded
		hideCurrentUsageCheckbox.target = self
		hideCurrentUsageCheckbox.action = #selector(visibilityOptionsChanged)
		hideTargetDailyUsageCheckbox.target = self
		hideTargetDailyUsageCheckbox.action = #selector(visibilityOptionsChanged)
		let visibilityOptions = NSStackView(views: [hideCurrentUsageCheckbox, hideTargetDailyUsageCheckbox])
		visibilityOptions.orientation = .vertical
		visibilityOptions.alignment = .leading
		visibilityOptions.spacing = 4

		let header = NSStackView(views: [titleLabel, NSView(), refreshButton])
		header.orientation = .horizontal
		header.alignment = .centerY
		header.distribution = .fill
		header.spacing = 8

		let actions = NSStackView(views: [editButton, frequencyButton])
		actions.orientation = .horizontal
		actions.alignment = .centerY
		actions.spacing = 8

		let content = NSStackView(views: [
			header,
			actualLabel,
			expectedLabel,
			dailyBudgetLabel,
			daysRemainingLabel,
			updatedLabel,
			visibilityOptions,
			messageLabel,
			actions,
		])
		content.orientation = .vertical
		content.alignment = .leading
		content.distribution = .fill
		content.spacing = 8
		content.translatesAutoresizingMaskIntoConstraints = false
		root.addSubview(content)
		NSLayoutConstraint.activate([
			content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
			content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
			content.topAnchor.constraint(equalTo: root.topAnchor, constant: 14),
			content.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -14),
		])
		view = root
	}

	func setVisibilityOptions(hideCurrentUsage: Bool, hideTargetDailyUsage: Bool) {
		hideCurrentUsageCheckbox.state = hideCurrentUsage ? .on : .off
		hideTargetDailyUsageCheckbox.state = hideTargetDailyUsage ? .on : .off
	}

	func showLoading() {
		messageLabel.stringValue = "Reading Copilot usage…"
	}

	func show(_ presentation: UsageMenuPresentation, checkedAt: Date) {
		actualLabel.stringValue = presentation.actualText
		expectedLabel.stringValue = presentation.expectedText
		dailyBudgetLabel.stringValue = presentation.dailyBudgetText
		daysRemainingLabel.stringValue = presentation.daysRemainingText
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		updatedLabel.stringValue = "Updated \(formatter.string(from: checkedAt))"
		messageLabel.stringValue = ""
		onStatusTitle?(presentation.statusTitle)
	}

	func showMessage(_ message: String) {
		messageLabel.stringValue = message
	}

	@objc private func refreshClicked() {
		onRefresh?()
	}

	@objc private func editHolidaysClicked() {
		onEditHolidays?()
	}

	@objc private func updateFrequencyClicked() {
		onUpdateFrequency?()
	}

	@objc private func visibilityOptionsChanged() {
		onVisibilityOptionsChanged?(
			hideCurrentUsageCheckbox.state == .on,
			hideTargetDailyUsageCheckbox.state == .on
		)
	}
}

import AppKit
import CopilotUsageCore
import Foundation

@main
struct CopilotUsageCommand {
    static func main() async {
        if CommandLine.arguments.contains("--print-usage") {
            printUsageOnce()
            return
        }

        let isScheduled = CommandLine.arguments.contains("--scheduled")
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let year = components.year, let month = components.month else {
            fputs("Could not determine the current month.\n", stderr)
            exit(1)
        }
        let monthKey = String(format: "%04d-%02d", year, month)
        let store = HolidayStore()

        if isScheduled {
            await runScheduledHolidayPrompt(
                now: now,
                year: year,
                month: month,
                monthKey: monthKey,
                calendar: calendar,
                store: store
            )
            return
        }

        guard requestLaunchConsent() else {
            print("Consent not granted; exiting without installing the reminder or opening the menu bar app.")
            return
        }

        do {
            try MonthlyHolidayScheduler.installIfNeeded(appBundlePath: Bundle.main.bundleURL.path)
        } catch {
            fputs("Monthly holiday reminders could not be installed: \(error.localizedDescription)\n", stderr)
        }

        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = CopilotUsageMenuBarApp()
        application.delegate = delegate
        application.run()
    }

    private static func printUsageOnce() {
        do {
            let percentage = try CopilotCLIUsageReader.readPercentage()
            print(UsagePercentOutput.line(percentage))
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func runScheduledHolidayPrompt(
        now: Date,
        year: Int,
        month: Int,
        monthKey: String,
        calendar: Calendar,
        store: HolidayStore
    ) async {
        do {
            guard try store.load(month: monthKey) == nil else { return }
            let suggestions = await fetchHolidaySuggestions(year: year, month: month)
            guard MonthlyPacing.isEligibleToPrompt(today: now, holidays: Set(suggestions), calendar: calendar) else {
                return
            }
            guard let selected = MonthlyHolidayPrompt.ask(monthDate: now, suggestions: suggestions, calendar: calendar) else {
                return
            }
            try store.save(month: monthKey, holidays: selected)
        } catch {
            fputs("Monthly holiday setup failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func fetchHolidaySuggestions(year: Int, month: Int) async -> [HolidayDate] {
        do {
            return try await MadridHolidayCalendar.fetchSuggestions(year: year)
                .filter { $0.month == month }
        } catch {
            fputs("Madrid holiday suggestions are unavailable; enter dates manually.\n", stderr)
            return []
        }
    }

    private static let consentPreferenceKey = "usage.consentMode"

    private static func requestLaunchConsent() -> Bool {
        let defaults = UserDefaults.standard
        switch UsageConsentPolicy.prompt(for: defaults.string(forKey: consentPreferenceKey)) {
        case .skip:
            return true
        case .confirmEveryLaunch:
            return UsageConsentPolicy.isAllowedByDialogOutput(confirmConsentForLaunch())
        case .choosePreference:
            guard let mode = UsageConsentPolicy.mode(fromDialogOutput: chooseConsentPreference()) else { return false }
            defaults.set(mode.rawValue, forKey: consentPreferenceKey)
            return true
        }
    }

    private static func chooseConsentPreference() -> String? {
        runConsentDialog(
            "display dialog \"Copilot Usage can stay in the menu bar, install a weekday 09:00 Madrid holiday reminder, and run the authenticated Copilot CLI locally when you refresh to read your active account's Plan usage. It does not capture the screen or control the mouse. Choose how you want to grant permission.\" with title \"Copilot Usage\" buttons {\"Cancel\", \"Ask Every Time\", \"Always Allow\"} default button \"Ask Every Time\" cancel button \"Cancel\" with icon note"
        )
    }

    private static func confirmConsentForLaunch() -> String? {
        runConsentDialog(
            "display dialog \"Allow Copilot Usage to stay in the menu bar and read your active account's Plan usage during this launch?\" with title \"Copilot Usage\" buttons {\"Cancel\", \"Allow\"} default button \"Allow\" cancel button \"Cancel\" with icon note"
        )
    }

    private static func runConsentDialog(_ script: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return String(data: output, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            fputs("Could not display the consent dialog: \(error.localizedDescription)\n", stderr)
            return nil
        }
    }

}

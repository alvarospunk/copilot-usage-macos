import Foundation

@main
struct UsagePercentParserTest {
    static func main() {
        guard UsageConsentPolicy.prompt(for: nil) == .choosePreference else {
            fputs("The first launch should ask the user to choose a consent preference.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.prompt(for: UsageConsentMode.alwaysAsk.rawValue) == .confirmEveryLaunch else {
            fputs("The always-ask preference should require confirmation on every launch.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.prompt(for: UsageConsentMode.alwaysAllow.rawValue) == .skip else {
            fputs("The always-allow preference should skip future consent prompts.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.prompt(for: "unknown") == .choosePreference else {
            fputs("An unknown consent preference should fail closed and ask again.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.mode(fromDialogOutput: "button returned:Always Allow") == .alwaysAllow else {
            fputs("The Always Allow dialog response should select persistent consent.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.mode(fromDialogOutput: "button returned:Ask Every Time") == .alwaysAsk else {
            fputs("The Ask Every Time dialog response should select repeated consent.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.mode(fromDialogOutput: "") == nil,
              !UsageConsentPolicy.isAllowedByDialogOutput("button returned:Cancel") else {
            fputs("Cancelled dialog responses must not grant or save consent.\n", stderr)
            exit(1)
        }
        guard UsageConsentPolicy.isAllowedByDialogOutput("button returned:Allow") else {
            fputs("An explicit per-launch Allow response should permit this launch.\n", stderr)
            exit(1)
        }

        guard CopilotCLIUsageReader.parsePercentage(from: "30%\n") == 30 else {
            fputs("Expected CLI Plan output to parse as 30%.\n", stderr)
            exit(1)
        }
        guard CopilotCLIUsageReader.parsePercentage(from: "27.5%\n") == 28 else {
            fputs("Expected decimal CLI Plan output to round to the nearest whole percent.\n", stderr)
            exit(1)
        }
        guard CopilotCLIUsageReader.parsePercentage(from: "Session 40%\n30%\n") == nil else {
            fputs("Expected mixed CLI output to be rejected.\n", stderr)
            exit(1)
        }

        MonthlyPacingTest.run()
        HolidayCalendarTest.run()
        MonthlyHolidaySchedulerTest.run()
        UsageMenuPresentationTest.run()
        UsageRefreshPolicyTest.run()
        guard UsagePercentOutput.line(25) == "25%" else {
            fputs("Usage percent output should be a single percentage token.\n", stderr)
            exit(1)
        }
    }
}

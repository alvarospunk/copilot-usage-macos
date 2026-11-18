#!/bin/sh
set -eu

cd "$(dirname "$0")"
test_binary="${TMPDIR:-/tmp}/copilot-usage-parser-test"
swiftc Sources/CopilotUsageCore/CopilotCLIUsageReader.swift Sources/CopilotUsageCore/MonthlyPacing.swift Sources/CopilotUsageCore/MadridHolidayCalendar.swift Sources/CopilotUsageCore/HolidayStore.swift Sources/CopilotUsageCore/MonthlyHolidayScheduler.swift Sources/CopilotUsageCore/UsageConsentPolicy.swift Sources/CopilotUsageCore/UsageMenuPresentation.swift Sources/CopilotUsageCore/UsageRefreshPolicy.swift Sources/CopilotUsageCore/UsagePercentOutput.swift Tests/MonthlyPacingTest.swift Tests/HolidayCalendarTest.swift Tests/MonthlyHolidaySchedulerTest.swift Tests/UsageMenuPresentationTest.swift Tests/UsageRefreshPolicyTest.swift Tests/UsagePercentParserTest.swift -o "$test_binary"
"$test_binary"

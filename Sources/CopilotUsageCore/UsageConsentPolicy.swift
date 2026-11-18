public enum UsageConsentMode: String {
	case alwaysAllow
	case alwaysAsk
}

public enum UsageConsentPrompt: Equatable {
	case choosePreference
	case confirmEveryLaunch
	case skip
}

public enum UsageConsentPolicy {
	public static func prompt(for storedMode: String?) -> UsageConsentPrompt {
		guard let storedMode, let mode = UsageConsentMode(rawValue: storedMode) else {
			return .choosePreference
		}

		switch mode {
		case .alwaysAllow:
			return .skip
		case .alwaysAsk:
			return .confirmEveryLaunch
		}
	}

	public static func mode(fromDialogOutput output: String?) -> UsageConsentMode? {
		switch buttonReturned(in: output) {
		case "Always Allow":
			return .alwaysAllow
		case "Ask Every Time":
			return .alwaysAsk
		default:
			return nil
		}
	}

	public static func isAllowedByDialogOutput(_ output: String?) -> Bool {
		buttonReturned(in: output) == "Allow"
	}

	private static func buttonReturned(in output: String?) -> String? {
		guard let output,
			  let range = output.range(of: "button returned:") else {
			return nil
		}
		return output[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
	}
}

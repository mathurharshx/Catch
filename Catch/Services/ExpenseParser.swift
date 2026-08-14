import Foundation

/// Lightweight helper to detect and extract basic expense data from raw natural language input.
public struct ParsedExpense: Equatable {
    public let amount: Double
    public let currency: String
    public let merchant: String
}

public enum ExpenseParser {
    /// Attempts to parse an amount, currency, and merchant description from raw text.
    public static func parse(text: String, defaultCurrency: String = "₹") -> ParsedExpense? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Common currency symbols / identifiers
        let patterns = [
            // Pattern 1: Symbol before number (e.g. ₹850 Starbucks, $14.50 Lunch, £20 groceries)
            #"(₹|\$|€|£|¥|Rs\.?|INR|USD|EUR|GBP)\s*([0-9]+(?:\.[0-9]{1,2})?)\s*(.*)"#,
            // Pattern 2: Number before symbol/rs (e.g. 850₹ Starbucks, 850 rs lunch, 850rs uber)
            #"([0-9]+(?:\.[0-9]{1,2})?)\s*(₹|\$|€|£|¥|rs|inr|usd|eur|gbp)\s*(.*)"#,
            // Pattern 3: Spent / Paid / Spent 850 on Starbucks / 850 Starbucks
            #"(?:spent|paid)?\s*([0-9]+(?:\.[0-9]{1,2})?)\s*(?:on|at|for)?\s*(.*)"#
        ]

        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
                
                if index == 0 { // Symbol first
                    let currRange = Range(match.range(at: 1), in: trimmed)
                    let amtRange = Range(match.range(at: 2), in: trimmed)
                    let descRange = Range(match.range(at: 3), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = Double(amtStr) {
                        let curr = currRange.map({ normalizeCurrency(String(trimmed[$0])) }) ?? defaultCurrency
                        var desc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if desc.lowercased().hasPrefix("on ") || desc.lowercased().hasPrefix("at ") || desc.lowercased().hasPrefix("for ") {
                            desc = String(desc.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        return ParsedExpense(amount: amount, currency: curr, merchant: desc.isEmpty ? trimmed : desc)
                    }
                } else if index == 1 { // Number first
                    let amtRange = Range(match.range(at: 1), in: trimmed)
                    let currRange = Range(match.range(at: 2), in: trimmed)
                    let descRange = Range(match.range(at: 3), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = Double(amtStr) {
                        let curr = currRange.map({ normalizeCurrency(String(trimmed[$0])) }) ?? defaultCurrency
                        var desc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if desc.lowercased().hasPrefix("on ") || desc.lowercased().hasPrefix("at ") || desc.lowercased().hasPrefix("for ") {
                            desc = String(desc.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        return ParsedExpense(amount: amount, currency: curr, merchant: desc.isEmpty ? trimmed : desc)
                    }
                } else if index == 2 { // Standalone number with words
                    let amtRange = Range(match.range(at: 1), in: trimmed)
                    let descRange = Range(match.range(at: 2), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = Double(amtStr) {
                        let desc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if !desc.isEmpty {
                            return ParsedExpense(amount: amount, currency: defaultCurrency, merchant: desc)
                        }
                    }
                }
            }
        }

        return nil
    }

    private static func normalizeCurrency(_ raw: String) -> String {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.contains("rs") || lower.contains("inr") || lower == "₹" {
            return "₹"
        }
        if lower == "$" || lower == "usd" {
            return "$"
        }
        if lower == "€" || lower == "eur" {
            return "€"
        }
        if lower == "£" || lower == "gbp" {
            return "£"
        }
        if lower == "¥" || lower == "jpy" {
            return "¥"
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

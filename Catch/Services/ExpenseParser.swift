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
            #"(₹|\$|€|£|¥|Rs\.?|INR|USD|EUR|GBP)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(.*)"#,
            // Pattern 2: Number before symbol/rs (e.g. 850₹ Starbucks, 850 rs lunch, 850rs uber)
            #"([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(₹|\$|€|£|¥|rs|inr|usd|eur|gbp)\s*(.*)"#,
            // Pattern 3: Number first, merchant after (e.g. 750 cafe, spent 450 on groceries, 180202 car rent)
            #"^(?:spent|paid)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:on|at|for)?\s*(.*)$"#,
            // Pattern 4: Merchant/text first, number at end (e.g. cafe 750, coffee 120, lunch for 350, car rent 180202)
            #"^(.+?)\s+(?:for|at|of|costs?|cost|spent|paid)?\s*(?:₹|\$|€|£|¥|rs|inr|usd|eur|gbp)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)$"#
        ]

        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {

                if index == 0 { // Symbol first
                    let currRange = Range(match.range(at: 1), in: trimmed)
                    let amtRange = Range(match.range(at: 2), in: trimmed)
                    let descRange = Range(match.range(at: 3), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = parseAmount(amtStr) {
                        let curr = currRange.map({ normalizeCurrency(String(trimmed[$0])) }) ?? defaultCurrency
                        let rawDesc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let desc = cleanMerchant(rawDesc)
                        return ParsedExpense(amount: amount, currency: curr, merchant: desc.isEmpty ? trimmed : desc)
                    }
                } else if index == 1 { // Number first with currency symbol/code
                    let amtRange = Range(match.range(at: 1), in: trimmed)
                    let currRange = Range(match.range(at: 2), in: trimmed)
                    let descRange = Range(match.range(at: 3), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = parseAmount(amtStr) {
                        let curr = currRange.map({ normalizeCurrency(String(trimmed[$0])) }) ?? defaultCurrency
                        let rawDesc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let desc = cleanMerchant(rawDesc)
                        return ParsedExpense(amount: amount, currency: curr, merchant: desc.isEmpty ? trimmed : desc)
                    }
                } else if index == 2 { // Standalone number or number first with optional words
                    let amtRange = Range(match.range(at: 1), in: trimmed)
                    let descRange = Range(match.range(at: 2), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = parseAmount(amtStr) {
                        let rawDesc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let desc = cleanMerchant(rawDesc)

                        // Avoid false positives like "10 steps to...", "2 hours of study"
                        let words = desc.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                        let nonExpenseUnits = ["step", "steps", "day", "days", "week", "weeks", "month", "months", "year", "years", "hour", "hours", "minute", "minutes", "am", "pm", "%", "percent", "people"]
                        if let firstWord = words.first?.lowercased(), nonExpenseUnits.contains(firstWord) {
                            continue
                        }

                        return ParsedExpense(amount: amount, currency: defaultCurrency, merchant: desc)
                    }
                } else if index == 3 { // Merchant first, number at end (e.g. cafe 750, coffee 120, car rent 180202)
                    let descRange = Range(match.range(at: 1), in: trimmed)
                    let amtRange = Range(match.range(at: 2), in: trimmed)

                    if let amtStr = amtRange.map({ String(trimmed[$0]) }),
                       let amount = parseAmount(amtStr) {
                        let rawDesc = descRange.map({ String(trimmed[$0]) })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let desc = cleanMerchant(rawDesc)

                        // Guard against sentences that end with codes/numbers (e.g. "The meeting room code is 4920")
                        let words = desc.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                        let nonExpenseWords = ["code", "pin", "password", "room", "page", "chapter", "is", "are", "was", "flight", "gate", "terminal", "seat", "version", "v", "phone", "number", "id"]
                        let hasNonExpenseWord = words.contains { nonExpenseWords.contains($0.lowercased()) }

                        if !desc.isEmpty && words.count <= 4 && !hasNonExpenseWord {
                            return ParsedExpense(amount: amount, currency: defaultCurrency, merchant: desc)
                        }
                    }
                }
            }
        }

        return nil
    }

    private static func parseAmount(_ raw: String) -> Double? {
        let clean = raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(clean)
    }

    private static func cleanMerchant(_ raw: String) -> String {
        var desc = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stopWords = ["on ", "at ", "for ", "in ", "to "]
        for word in stopWords {
            if desc.lowercased().hasPrefix(word) {
                desc = String(desc.dropFirst(word.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if desc.lowercased().hasSuffix(" " + word.trimmingCharacters(in: .whitespaces)) {
                desc = String(desc.dropLast(word.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return desc
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

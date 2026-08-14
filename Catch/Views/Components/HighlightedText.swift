import SwiftUI

/// Renders text with matching search queries highlighted in real-time.
public struct HighlightedText: View {
    public let text: String
    public let query: String
    public var isStrikethrough: Bool = false
    public var textColor: Color = Theme.primaryText
    public var highlightColor: Color = Theme.brandTint

    public init(
        text: String,
        query: String = "",
        isStrikethrough: Bool = false,
        textColor: Color = Theme.primaryText,
        highlightColor: Color = Theme.brandTint
    ) {
        self.text = text
        self.query = query
        self.isStrikethrough = isStrikethrough
        self.textColor = textColor
        self.highlightColor = highlightColor
    }

    public var body: some View {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(textColor)
                .strikethrough(isStrikethrough, color: textColor)
        } else {
            renderedHighlightedText
                .font(.system(size: 15, weight: .regular))
                .strikethrough(isStrikethrough, color: textColor)
        }
    }

    private var renderedHighlightedText: Text {
        guard let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: query), options: .caseInsensitive) else {
            return Text(text).foregroundColor(textColor)
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        guard !matches.isEmpty else {
            return Text(text).foregroundColor(textColor)
        }

        var result = Text("")
        var currentIndex = 0

        for match in matches {
            let matchRange = match.range
            if matchRange.location > currentIndex {
                let nonMatchRange = NSRange(location: currentIndex, length: matchRange.location - currentIndex)
                let nonMatchStr = nsString.substring(with: nonMatchRange)
                result = result + Text(nonMatchStr).foregroundColor(textColor)
            }

            let matchStr = nsString.substring(with: matchRange)
            result = result + Text(matchStr)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(highlightColor)

            currentIndex = matchRange.location + matchRange.length
        }

        if currentIndex < nsString.length {
            let remainingRange = NSRange(location: currentIndex, length: nsString.length - currentIndex)
            let remainingStr = nsString.substring(with: remainingRange)
            result = result + Text(remainingStr).foregroundColor(textColor)
        }

        return result
    }
}

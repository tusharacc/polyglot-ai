//
//  MarkdownHelper.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import SwiftUI

// MARK: - Custom Markdown Text View
struct MarkdownText: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parseMarkdown(content).enumerated()), id: \.offset) { _, block in
                block
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseMarkdown(_ text: String) -> [AnyView] {
        var blocks: [AnyView] = []
        var currentText = ""
        let lines = text.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Code blocks
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                // Save any accumulated text
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }

                // Extract language (if any)
                let language = line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // Collect code block content
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }

                let code = codeLines.joined(separator: "\n")
                blocks.append(AnyView(CodeBlockView(code: code, language: language)))
                i += 1
                continue
            }

            // Headers
            if line.hasPrefix("# ") {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }
                blocks.append(AnyView(
                    Text(line.replacingOccurrences(of: "# ", with: ""))
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.vertical, 4)
                ))
                i += 1
                continue
            }

            if line.hasPrefix("## ") {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }
                blocks.append(AnyView(
                    Text(line.replacingOccurrences(of: "## ", with: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.vertical, 3)
                ))
                i += 1
                continue
            }

            if line.hasPrefix("### ") {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }
                blocks.append(AnyView(
                    Text(line.replacingOccurrences(of: "### ", with: ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.vertical, 2)
                ))
                i += 1
                continue
            }

            // List items
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("- ") ||
               line.trimmingCharacters(in: .whitespaces).hasPrefix("* ") {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }

                let listText = line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "^[-*]\\s+", with: "", options: .regularExpression)

                blocks.append(AnyView(
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                        renderInlineMarkdown(listText)
                    }
                    .padding(.leading, 8)
                ))
                i += 1
                continue
            }

            // Numbered lists
            if let match = line.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }

                let number = String(line[match]).trimmingCharacters(in: .whitespaces)
                let listText = String(line[match.upperBound...])

                blocks.append(AnyView(
                    HStack(alignment: .top, spacing: 8) {
                        Text(number)
                            .font(.body)
                            .frame(width: 24, alignment: .trailing)
                        renderInlineMarkdown(listText)
                    }
                    .padding(.leading, 8)
                ))
                i += 1
                continue
            }

            // Empty lines create paragraph breaks
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !currentText.isEmpty {
                    blocks.append(AnyView(renderInlineMarkdown(currentText)))
                    currentText = ""
                }
                i += 1
                continue
            }

            // Regular text
            if !currentText.isEmpty {
                currentText += "\n"
            }
            currentText += line
            i += 1
        }

        // Add any remaining text
        if !currentText.isEmpty {
            blocks.append(AnyView(renderInlineMarkdown(currentText)))
        }

        return blocks
    }

    private func renderInlineMarkdown(_ text: String) -> Text {
        var result = Text("")
        var processedText = text

        // Replace inline code with placeholder and track them
        var codeSnippets: [String] = []
        var codeIndex = 0

        while let codeRange = processedText.range(of: "`[^`]+`", options: .regularExpression) {
            let code = String(processedText[codeRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: "`"))
            codeSnippets.append(code)
            processedText.replaceSubrange(codeRange, with: "⟨CODE\(codeIndex)⟩")
            codeIndex += 1
        }

        // Now process bold/italic
        let formatted = formatInlineText(processedText)

        // Build final text with code snippets styled
        let components = formatted.split(separator: "⟨", omittingEmptySubsequences: false)

        for (index, component) in components.enumerated() {
            if index == 0 && !component.isEmpty {
                result = result + applyFormatting(String(component))
            } else if component.hasPrefix("CODE") {
                // Extract code index
                if let endIndex = component.firstIndex(of: "⟩"),
                   let codeIdx = Int(component.dropFirst(4).prefix(upTo: endIndex)),
                   codeIdx < codeSnippets.count {
                    result = result + Text(codeSnippets[codeIdx])
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.purple)
                        .bold()

                    // Add text after the code marker
                    let afterCode = component.suffix(from: component.index(after: endIndex))
                    if !afterCode.isEmpty {
                        result = result + applyFormatting(String(afterCode))
                    }
                }
            }
        }

        return result
    }

    private func formatInlineText(_ text: String) -> String {
        var result = text

        // Process formatting markers by replacing with AttributedString-compatible versions
        // Bold italic
        result = result.replacingOccurrences(
            of: "\\*\\*\\*([^*]+)\\*\\*\\*",
            with: "⟪BI:$1⟫",
            options: .regularExpression
        )
        // Bold
        result = result.replacingOccurrences(
            of: "\\*\\*([^*]+)\\*\\*",
            with: "⟪B:$1⟫",
            options: .regularExpression
        )
        // Italic
        result = result.replacingOccurrences(
            of: "\\*([^*]+)\\*",
            with: "⟪I:$1⟫",
            options: .regularExpression
        )
        // Italic underscore
        result = result.replacingOccurrences(
            of: "_([^_]+)_",
            with: "⟪I:$1⟫",
            options: .regularExpression
        )

        return result
    }

    private func applyFormatting(_ text: String) -> Text {
        var result = Text("")
        var remaining = text

        while let markerRange = remaining.range(of: "⟪[BI]+:[^⟫]+⟫", options: .regularExpression) {
            // Add text before marker
            let before = String(remaining[..<markerRange.lowerBound])
            if !before.isEmpty {
                result = result + Text(before)
            }

            // Process marker
            let marker = String(remaining[markerRange])
            if let colonIndex = marker.firstIndex(of: ":"),
               let endIndex = marker.firstIndex(of: "⟫") {
                let format = String(marker[marker.index(after: marker.startIndex)..<colonIndex])
                let content = String(marker[marker.index(after: colonIndex)..<endIndex])

                if format == "BI" {
                    result = result + Text(content).bold().italic()
                } else if format == "B" {
                    result = result + Text(content).bold()
                } else if format == "I" {
                    result = result + Text(content).italic()
                }
            }

            remaining = String(remaining[markerRange.upperBound...])
        }

        // Add remaining text
        if !remaining.isEmpty {
            result = result + Text(remaining)
        }

        return result
    }
}

// MARK: - Code Block View
struct CodeBlockView: View {
    let code: String
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language label
            if !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = code
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.3))
            }

            // Code content
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(12)
                    .textSelection(.enabled)
            }
            .background(Color.black.opacity(0.85))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

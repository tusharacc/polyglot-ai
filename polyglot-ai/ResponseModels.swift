//
//  ResponseModels.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import Foundation
import SwiftUI

enum ResponseStatus: Equatable {
    case idle
    case loading
    case success
    case failed(String)
    case noApiKey
    case disabled
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .loading: return "arrow.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .noApiKey: return "exclamationmark.triangle.fill"
        case .disabled: return "minus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .loading: return .blue
        case .success: return .green
        case .failed: return .red
        case .noApiKey: return .orange
        case .disabled: return .gray
        }
    }
    
    var statusText: String {
        switch self {
        case .idle: return "Ready"
        case .loading: return "Loading..."
        case .success: return "Complete"
        case .failed(let error): return "Error: \(error)"
        case .noApiKey: return "No API Key"
        case .disabled: return "Disabled"
        }
    }
}

struct LLMResponse {
    let provider: APIProvider
    var status: ResponseStatus = .idle
    var content: String = ""
    var timestamp: Date?
    var isExpanded: Bool = false
    
    var previewContent: String {
        let lines = content.components(separatedBy: .newlines)
        let previewLines = lines.prefix(3)
        let preview = previewLines.joined(separator: "\n")
        return lines.count > 3 ? preview + "..." : preview
    }
    
    var hasContent: Bool {
        return !content.isEmpty && status == .success
    }
}

struct ConversationSummary {
    let originalPrompt: String
    var responses: [LLMResponse]
    var summaryContent: String = ""
    var summaryStatus: ResponseStatus = .idle
    var timestamp: Date?
    
    var isReady: Bool {
        return summaryStatus == .success && !summaryContent.isEmpty
    }
    
    var canSummarize: Bool {
        return responses.filter { $0.hasContent }.count >= 2
    }
    
    var contextForFollowUp: String {
        guard isReady else { return originalPrompt }
        return """
        Previous conversation:
        User: \(originalPrompt)
        
        Summary of AI responses: \(summaryContent)
        
        New question:
        """
    }
}

struct UserQuestion {
    let question: String
    let timestamp: Date
    let isFollowUp: Bool
    
    init(question: String, isFollowUp: Bool = false) {
        self.question = question
        self.timestamp = Date()
        self.isFollowUp = isFollowUp
    }
}

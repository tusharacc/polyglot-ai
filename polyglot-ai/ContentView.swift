//
//  ContentView.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isClaude = true
    @State private var isChatGPT = true
    @State private var isGemini = true
    @State private var prompt = ""
    @State private var showingSettings = false
    @State private var responses: [LLMResponse] = []
    @State private var hasStartedResponse = false
    @State private var isPromptCollapsed = false
    @State private var conversationSummary: ConversationSummary?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                promptSection
                
                if hasStartedResponse {
                    responseSection
                } else {
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if hasStartedResponse {
                        Button(action: {
                            endChat()
                        }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var promptSection: some View {
        VStack(spacing: isPromptCollapsed ? 10 : 30) {
            Text("POLYGLOT AI")
                .font(isPromptCollapsed ? .title2 : .largeTitle)
                .fontWeight(.bold)
                .padding(.top, isPromptCollapsed ? 10 : 30)
                .animation(.easeInOut(duration: 0.3), value: isPromptCollapsed)
        
            if !isPromptCollapsed {
                providerCheckboxes
            }
            
            promptInputArea
            
            sendButton
        }
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground))
        .onTapGesture {
            if isPromptCollapsed {
                withAnimation {
                    isPromptCollapsed = false
                }
            }
        }
    }
    
    private var providerCheckboxes: some View {
        HStack(spacing: 40) {
                VStack {
                    Image(systemName: isClaude ? "checkmark.square.fill" : "square")
                        .foregroundColor(isClaude ? .blue : .gray)
                        .font(.title2)
                        .onTapGesture {
                            isClaude.toggle()
                        }
                    Text("Claude")
                        .font(.caption)
                }
                
                VStack {
                    Image(systemName: isChatGPT ? "checkmark.square.fill" : "square")
                        .foregroundColor(isChatGPT ? .green : .gray)
                        .font(.title2)
                        .onTapGesture {
                            isChatGPT.toggle()
                        }
                    Text("ChatGPT")
                        .font(.caption)
                }
                
                VStack {
                    Image(systemName: isGemini ? "checkmark.square.fill" : "square")
                        .foregroundColor(isGemini ? .orange : .gray)
                        .font(.title2)
                        .onTapGesture {
                            isGemini.toggle()
                        }
                    Text("Gemini")
                        .font(.caption)
                }
            }
    }
    
    private var promptInputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isPromptCollapsed {
                Text("Enter your prompt:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
            if isPromptCollapsed {
                HStack {
                    Text(prompt.isEmpty ? "Tap to enter prompt" : String(prompt.prefix(50)) + (prompt.count > 50 ? "..." : ""))
                        .font(.body)
                        .foregroundColor(prompt.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                TextEditor(text: $prompt)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPromptCollapsed)
    }
    
    private var sendButton: some View {
        Group {
            if !hasStartedResponse {
                Button(action: {
                    sendPrompt()
                }) {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!isClaude && !isChatGPT && !isGemini))
            }
        }
    }
    
    private var responseSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(responses.indices, id: \.self) { index in
                    ResponseCard(response: $responses[index])
                }
                
                summarySection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            if let summary = conversationSummary {
                if summary.summaryStatus == .idle && summary.canSummarize {
                    summaryButton
                } else if summary.summaryStatus == .loading {
                    loadingSummaryCard
                } else if summary.summaryStatus == .success {
                    summaryResultCard(summary)
                } else if case .failed(let error) = summary.summaryStatus {
                    summaryErrorCard(error)
                }
            }
        }
    }
    
    private var summaryButton: some View {
        Button(action: {
            generateSummary()
        }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text("Generate Summary")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var loadingSummaryCard: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating summary...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 1)
        )
    }
    
    private func summaryResultCard(_ summary: ConversationSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.green)
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if let timestamp = summary.timestamp {
                    Text(timeString(from: timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            ScrollView {
                Text(parseMarkdown(summary.summaryContent))
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 200)
            
            HStack {
                Button("Copy Summary") {
                    UIPasteboard.general.string = summary.summaryContent
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 2)
        )
    }
    
    private func summaryErrorCard(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Summary Failed")
                    .font(.headline)
                Spacer()
            }
            
            Text(error)
                .font(.body)
                .foregroundColor(.red)
            
            Button("Retry") {
                generateSummary()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 1)
        )
    }
    
    private func sendPrompt() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard isClaude || isChatGPT || isGemini else { return }
        
        // Initialize responses for selected providers
        responses.removeAll()
        conversationSummary = nil
        
        if isClaude {
            let status: ResponseStatus = KeychainManager.shared.hasApiKey(for: .claude) ? .loading : .noApiKey
            responses.append(LLMResponse(provider: .claude, status: status))
        }
        
        if isChatGPT {
            let status: ResponseStatus = KeychainManager.shared.hasApiKey(for: .openai) ? .loading : .noApiKey
            responses.append(LLMResponse(provider: .openai, status: status))
        }
        
        if isGemini {
            let status: ResponseStatus = KeychainManager.shared.hasApiKey(for: .gemini) ? .loading : .noApiKey
            responses.append(LLMResponse(provider: .gemini, status: status))
        }
        
        // Collapse prompt area and show responses
        withAnimation {
            hasStartedResponse = true
            isPromptCollapsed = true
        }
        
        // Test real API keys (just validation for now)
        testAPIKeys()
        
        // Initialize conversation summary
        conversationSummary = ConversationSummary(
            originalPrompt: prompt,
            responses: responses
        )
        
        // Make actual API calls
        makeRealAPICallsAsync()
    }
    
    private func simulateAPIResponses() {
        for (index, response) in responses.enumerated() {
            if response.status == .loading {
                let delay = Double.random(in: 1.0...4.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Simulate different response scenarios
                    let scenarios = ["success", "success", "success", "error"] // 75% success rate
                    let scenario = scenarios.randomElement()!
                    
                    if scenario == "success" {
                        let sampleResponses = [
                            "This is a sample response from \(response.provider.displayName). The response demonstrates how the app handles multiple LLM responses with different lengths and content types. This text is long enough to test the expand/collapse functionality.",
                            "Here's another example response that shows how different providers might respond to the same prompt with varying perspectives and approaches.",
                            "A shorter response example."
                        ]
                        
                        responses[index].status = .success
                        responses[index].content = sampleResponses.randomElement()!
                        responses[index].timestamp = Date()
                    } else {
                        let errors = ["Rate limit exceeded", "API key invalid", "Service temporarily unavailable"]
                        responses[index].status = .failed(errors.randomElement()!)
                    }
                }
            }
        }
    }
    
    private func testAPIKeys() {
        // Test retrieval of actual API keys from keychain
        print("=== API Key Validation Test ===")
        
        for provider in [APIProvider.claude, .openai, .gemini] {
            if let key = KeychainManager.shared.retrieve(for: provider) {
                let preview = String(key.prefix(10)) + "..." + String(key.suffix(4))
                print("✅ \(provider.displayName): \(preview)")
            } else {
                print("❌ \(provider.displayName): No API key found")
            }
        }
        
        print("===============================")
    }
    
    private func makeRealAPICallsAsync() {
        for (index, response) in responses.enumerated() {
            if response.status == .loading {
                Task {
                    let result = await APIService.shared.sendPrompt(prompt, to: response.provider)
                    
                    await MainActor.run {
                        switch result {
                        case .success(let content):
                            responses[index].status = .success
                            responses[index].content = content
                            responses[index].timestamp = Date()
                        case .failure(let error):
                            responses[index].status = .failed(error.localizedDescription)
                        }
                        
                        // Update conversation summary with new responses
                        conversationSummary?.responses = responses
                    }
                }
            }
        }
    }
    
    private func generateSummary() {
        guard let summary = conversationSummary else { return }
        
        conversationSummary?.summaryStatus = .loading
        
        Task {
            let result = await APIService.shared.generateSummary(
                from: summary.responses,
                originalPrompt: summary.originalPrompt
            )
            
            await MainActor.run {
                switch result {
                case .success(let summaryContent):
                    conversationSummary?.summaryContent = summaryContent
                    conversationSummary?.summaryStatus = .success
                    conversationSummary?.timestamp = Date()
                case .failure(let error):
                    conversationSummary?.summaryStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func endChat() {
        withAnimation {
            hasStartedResponse = false
            isPromptCollapsed = false
            responses.removeAll()
            conversationSummary = nil
            prompt = ""
        }
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            let attributedString = try AttributedString(markdown: text)
            return attributedString
        } catch {
            print("Markdown parsing failed: \(error.localizedDescription)")
            return AttributedString(text)
        }
    }
}

#Preview {
    ContentView()
}

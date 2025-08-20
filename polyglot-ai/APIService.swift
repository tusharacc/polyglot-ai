//
//  APIService.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func sendPrompt(_ prompt: String, to provider: APIProvider) async -> Result<String, HTTPError> {
        guard let apiKey = KeychainManager.shared.retrieve(for: provider) else {
            return .failure(.httpError(401, "No API key found"))
        }
        
        switch provider {
        case .openai:
            return await sendToOpenAI(prompt: prompt, apiKey: apiKey)
        case .claude:
            return await sendToClaude(prompt: prompt, apiKey: apiKey)
        case .gemini:
            return await sendToGemini(prompt: prompt, apiKey: apiKey)
        }
    }
    
    func generateSummary(from responses: [LLMResponse], originalPrompt: String) async -> Result<String, HTTPError> {
        // Use Claude for summarization as it's best at this task
        guard let claudeApiKey = KeychainManager.shared.retrieve(for: .claude) else {
            return .failure(.httpError(401, "Claude API key required for summarization"))
        }
        
        // Filter successful responses
        let successfulResponses = responses.filter { $0.hasContent }
        
        guard successfulResponses.count >= 2 else {
            return .failure(.httpError(400, "Need at least 2 successful responses to summarize"))
        }
        
        // Create summarization prompt
        let summaryPrompt = buildSummaryPrompt(originalPrompt: originalPrompt, responses: successfulResponses)
        
        // Send to Claude for summarization
        return await sendToClaude(prompt: summaryPrompt, apiKey: claudeApiKey)
    }
    
    private func buildSummaryPrompt(originalPrompt: String, responses: [LLMResponse]) -> String {
        var prompt = """
        Please create a comprehensive summary that synthesizes the following AI responses to this question:
        
        Original Question: "\(originalPrompt)"
        
        AI Responses:
        """
        
        for (index, response) in responses.enumerated() {
            prompt += """
            
            \(index + 1). \(response.provider.displayName):
            \(response.content)
            
            """
        }
        
        prompt += """
        
        Instructions:
        - Combine the best insights from each response
        - Resolve any conflicts or contradictions
        - Present as one coherent, comprehensive answer
        - Preserve important details and nuances
        - Keep the summary well-structured and easy to understand
        - If responses disagree, explain the different perspectives
        
        Summary:
        """
        
        return prompt
    }
}

// MARK: - OpenAI Integration
extension APIService {
    private func sendToOpenAI(prompt: String, apiKey: String) async -> Result<String, HTTPError> {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return .failure(.invalidURL)
        }
        
        let request = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [OpenAIMessage(role: "user", content: prompt)],
            maxTokens: 1000,
            temperature: 0.7
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.httpError(httpResponse.statusCode, errorMessage))
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let firstChoice = openAIResponse.choices.first else {
                return .failure(.noData)
            }
            
            return .success(firstChoice.message.content)
            
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - Claude Integration
extension APIService {
    private func sendToClaude(prompt: String, apiKey: String) async -> Result<String, HTTPError> {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return .failure(.invalidURL)
        }
        
        let request = ClaudeRequest(
            model: "claude-opus-4-1-20250805",
            maxTokens: 1024,
            messages: [ClaudeMessage(role: "user", content: prompt)],
            temperature: 0.7
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.httpError(httpResponse.statusCode, errorMessage))
            }
            
            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            
            guard let firstContent = claudeResponse.content.first else {
                return .failure(.noData)
            }
            
            return .success(firstContent.text)
            
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - Gemini Integration
extension APIService {
    private func sendToGemini(prompt: String, apiKey: String) async -> Result<String, HTTPError> {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent") else {
            return .failure(.invalidURL)
        }
        
        let request = GeminiRequest(
            contents: [GeminiContent(
                parts: [GeminiPart(text: prompt)],
                role: "user"
            )],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 2048
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            debugPrint(data)
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(.httpError(httpResponse.statusCode, errorMessage))
            }
            
            // Print successful response body
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ Gemini response body:")
                print(responseString)
            }
            
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let firstCandidate = geminiResponse.candidates.first else {
                return .failure(.noData)
            }
            
            // Check for MAX_TOKENS finish reason
            if firstCandidate.finishReason == "MAX_TOKENS" {
                return .failure(.httpError(400, "Response truncated due to max tokens limit"))
            }
            
            // Check if parts exist (they might be missing on certain responses)
            guard let parts = firstCandidate.content.parts,
                  let firstPart = parts.first else {
                return .failure(.noData)
            }
            
            return .success(firstPart.text)
            
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }
}

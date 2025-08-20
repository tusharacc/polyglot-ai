//
//  KeychainManager.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import Foundation
import Security

enum APIProvider: String, CaseIterable {
    case openai = "openai_api_key"
    case claude = "claude_api_key" 
    case gemini = "gemini_api_key"
    
    var displayName: String {
        switch self {
        case .openai: return "ChatGPT (OpenAI)"
        case .claude: return "Claude (Anthropic)"
        case .gemini: return "Gemini (Google)"
        }
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    private let service = Bundle.main.bundleIdentifier ?? "com.polyglot-ai"
    
    func save(apiKey: String, for provider: APIProvider) -> Bool {
        let data = Data(apiKey.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieve(for provider: APIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    func delete(for provider: APIProvider) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    func hasApiKey(for provider: APIProvider) -> Bool {
        return retrieve(for: provider) != nil
    }
}
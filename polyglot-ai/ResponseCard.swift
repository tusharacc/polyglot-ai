//
//  ResponseCard.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import SwiftUI

struct ResponseCard: View {
    @Binding var response: LLMResponse
    @State private var showingCopyAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if response.status != .idle && response.status != .disabled && response.status != .noApiKey {
                content
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(response.status.color, lineWidth: response.status == .success || response.status == .failed("") ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.3), value: response.isExpanded)
        .animation(.easeInOut(duration: 0.3), value: response.status)
    }
    
    private var header: some View {
        HStack {
            Text(response.provider.displayName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                if response.status == .loading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Image(systemName: response.status.icon)
                    .foregroundColor(response.status.color)
                    .font(.title3)
                
                if let timestamp = response.timestamp, response.status == .success {
                    Text(timeString(from: timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if response.hasContent {
                withAnimation {
                    response.isExpanded.toggle()
                }
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(response.status.statusText)
                    .font(.caption)
                    .foregroundColor(response.status.color)
                
                if response.hasContent {
                    contentText
                } else if case .failed(let error) = response.status {
                    errorContent(error)
                }
            }
            .padding(.horizontal)
            
            if response.hasContent {
                actionButtons
            } else if case .failed = response.status {
                retryButton
            }
        }
        .padding(.bottom)
    }
    
    private var contentText: some View {
        ScrollView {
            Text(response.isExpanded ? response.content : response.previewContent)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        .frame(maxHeight: response.isExpanded ? 300 : 80)
        .animation(.easeInOut(duration: 0.3), value: response.isExpanded)
    }
    
    private func errorContent(_ error: String) -> some View {
        Text(error)
            .font(.body)
            .foregroundColor(.red)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var actionButtons: some View {
        HStack {
            Button(action: {
                copyToClipboard()
            }) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            if response.content.components(separatedBy: .newlines).count > 3 {
                Button(action: {
                    withAnimation {
                        response.isExpanded.toggle()
                    }
                }) {
                    Label(response.isExpanded ? "Collapse" : "Expand", 
                          systemImage: response.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }
    
    private var retryButton: some View {
        HStack {
            Button(action: {
                // TODO: Implement retry functionality
                print("Retry \(response.provider.displayName)")
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = response.content
        showingCopyAlert = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Hide alert after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingCopyAlert = false
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        ResponseCard(response: .constant(LLMResponse(
            provider: .claude,
            status: .success,
            content: "This is a sample response from Claude. It can be quite long and will show a preview initially, but can be expanded to show the full content.",
            timestamp: Date()
        )))
        
        ResponseCard(response: .constant(LLMResponse(
            provider: .openai,
            status: .loading
        )))
        
        ResponseCard(response: .constant(LLMResponse(
            provider: .gemini,
            status: .failed("Rate limit exceeded")
        )))
    }
    .padding()
}
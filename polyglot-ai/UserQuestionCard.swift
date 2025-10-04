//
//  UserQuestionCard.swift
//  polyglot-ai
//
//  Created by Tushar Saurabh on 8/19/25.
//

import SwiftUI

struct UserQuestionCard: View {
    let userQuestion: UserQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text(userQuestion.isFollowUp ? "You asked (follow-up):" : "You asked:")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(timeString(from: userQuestion.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()

            MarkdownText(content: userQuestion.question)
                .padding(.horizontal, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
}

#Preview {
    VStack(spacing: 16) {
        UserQuestionCard(userQuestion: UserQuestion(
            question: "What are the main benefits of using Swift for iOS development?"
        ))
        
        UserQuestionCard(userQuestion: UserQuestion(
            question: "Can you explain more about **memory management** in Swift?",
            isFollowUp: true
        ))
    }
    .padding()
}
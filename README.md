# Polyglot AI

A SwiftUI-based iOS application that allows users to query multiple Large Language Models (LLMs) simultaneously and compare their responses in real-time.

## 🚀 Features

### Multi-LLM Chat Interface
- **Simultaneous Queries**: Send prompts to Claude (Anthropic), ChatGPT (OpenAI), and Gemini (Google) at once
- **Response Comparison**: View responses from all selected LLMs side-by-side in expandable cards
- **Provider Selection**: Toggle between different LLM providers via intuitive checkboxes

### Advanced Conversation Management
- **AI-Powered Summarization**: Generate comprehensive summaries of multi-LLM conversations using Claude
- **Contextual Follow-ups**: Ask follow-up questions that include full conversation history
- **Conversation Threading**: Maintain organized threads with user questions and LLM responses
- **Context Preservation**: Follow-up questions automatically include previous conversation context

### Rich Text & UI Features
- **Markdown Rendering**: Full markdown support for formatted responses including headers, lists, code blocks, and links
- **Expandable Interface**: Collapsible prompt area and expandable response cards for optimal screen usage
- **Copy & Share**: One-tap copying of responses to clipboard with haptic feedback
- **Real-time Status**: Live status indicators for loading, success, failure, and API key states

### Security & Privacy
- **Secure API Key Storage**: Store API keys securely in iOS Keychain
- **Local Processing**: All data processing happens on-device
- **No Data Sharing**: API keys and conversations are never shared externally

## 📱 Screenshots

| Main Interface | Settings | Conversation Thread |
|---|---|---|
| Multi-LLM chat interface | Secure API key management | Threaded conversations |

## 🛠 Installation & Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later
- API keys from one or more providers:
  - [OpenAI API Key](https://platform.openai.com/api-keys)
  - [Anthropic API Key](https://console.anthropic.com/)
  - [Google AI API Key](https://ai.google.dev/)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/polyglot-ai.git
   cd polyglot-ai
   ```

2. Open the project in Xcode:
   ```bash
   open polyglot-ai.xcodeproj
   ```

3. Build and run the project on your iOS device or simulator

### API Key Configuration
1. Launch the app
2. Tap the gear icon (⚙️) in the top-right corner
3. Enter your API keys for desired providers:
   - **OpenAI**: Your OpenAI API key for ChatGPT access
   - **Anthropic**: Your Anthropic API key for Claude access
   - **Google**: Your Google AI API key for Gemini access
4. Tap "Save" for each provider
5. API keys are stored securely in your device's keychain

## 🏗 Architecture

### Project Structure
```
polyglot-ai/
├── polyglot_aiApp.swift          # App entry point
├── ContentView.swift             # Main chat interface
├── SettingsView.swift            # API key management
├── ResponseCard.swift            # Individual LLM response UI
├── UserQuestionCard.swift        # User question display
├── APIService.swift              # API integration layer
├── APIModels.swift               # API request/response models
├── ResponseModels.swift          # UI data models
├── KeychainManager.swift         # Secure storage
└── Assets.xcassets/              # App icons and assets
```

### Core Components

#### `ContentView.swift`
- Main chat interface with provider selection
- Conversation management and threading
- Summary generation and follow-up questions
- UI state management and animations

#### `APIService.swift`
- Unified API client for all LLM providers
- Async/await networking with proper error handling
- Request/response transformation
- Summary generation orchestration

#### `KeychainManager.swift`
- Secure API key storage using iOS Keychain
- CRUD operations for API credentials
- Provider-specific key management

#### `ResponseModels.swift`
- Data models for UI state management
- Conversation threading structures
- Status tracking and validation

## 🔧 Technical Details

### Supported LLM APIs
- **OpenAI**: GPT-3.5-turbo via Chat Completions API
- **Anthropic**: Claude Opus 4 via Messages API
- **Google**: Gemini 2.5 Flash via Generate Content API

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Swift Concurrency**: Async/await for API calls
- **Keychain Services**: Secure credential storage
- **Markdown Rendering**: Native AttributedString markdown parsing
- **Haptic Feedback**: Enhanced user experience

### API Integration Features
- **Timeout Handling**: 30-second request timeout, 60-second resource timeout
- **Error Recovery**: Graceful handling of rate limits, network errors, and API failures
- **Response Validation**: Comprehensive response parsing and validation
- **Token Management**: Appropriate token limits for each provider

## 🚦 Usage

### Basic Chat
1. Select desired LLM providers using checkboxes
2. Enter your prompt in the text area
3. Tap "Send" to query all selected providers simultaneously
4. View responses as they arrive in real-time
5. Expand/collapse responses for detailed viewing
6. Copy responses to clipboard as needed

### Conversation Summarization
1. After receiving responses from multiple LLMs
2. Tap "Generate Summary" button
3. Claude will synthesize all responses into a comprehensive summary
4. View the unified summary with combined insights

### Follow-up Questions
1. After generating a summary, tap "💬 Ask Follow-up"
2. Enter your follow-up question
3. The question is sent to all selected LLMs with full conversation context
4. Responses maintain the conversation thread

### Settings Management
1. Tap the gear icon (⚙️) to access settings
2. Add, update, or delete API keys for each provider
3. Visual indicators show which providers have valid keys
4. All keys are stored securely in the device keychain

## 🔍 Troubleshooting

### Common Issues

#### "No API Key" Error
- **Solution**: Add valid API keys in Settings for the providers you want to use

#### "Rate limit exceeded" Error
- **Solution**: Wait a few minutes and try again, or check your API usage limits

#### Responses not loading
- **Solution**: Check your internet connection and verify API keys are valid

#### App crashes or unexpected behavior
- **Solution**: Restart the app, ensure iOS version compatibility

### Debug Information
The app includes comprehensive logging for API calls and responses. Check the Xcode console for detailed error messages and request/response information.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift and SwiftUI best practices
- Maintain secure handling of API keys
- Add appropriate error handling for new features
- Update documentation for any API changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenAI](https://openai.com/) for GPT models and API
- [Anthropic](https://anthropic.com/) for Claude models and API
- [Google](https://ai.google.dev/) for Gemini models and API
- SwiftUI community for inspiration and best practices

## 📞 Support

For support, feature requests, or bug reports, please [open an issue](https://github.com/yourusername/polyglot-ai/issues) on GitHub.

---

**Made with ❤️ using SwiftUI**
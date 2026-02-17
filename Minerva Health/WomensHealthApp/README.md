# Women's Health Companion App

A comprehensive iOS app for tracking women's health with an AI-powered companion, built with SwiftUI.

## Features

### 📅 Cycle Tracking
- Track period days with intuitive calendar interface
- Automatic cycle length and period duration calculations
- Fertility window and ovulation predictions
- Visual cycle history with statistics

### 🌡️ Temperature Logging (NEW)
- Log basal body temperature (BBT) daily
- Support for Celsius and Fahrenheit
- Temperature chart visualization
- Quick-select common temperature values

### 📊 Symptom & Mood Tracking
- Comprehensive symptom selection (cramps, headache, fatigue, etc.)
- Mood tracking with emoji indicators
- Discharge type tracking with descriptions

### 🎨 Enhanced Discharge Tracking (NEW)
- When "Abnormal" discharge is selected, color options appear:
  - Clear, White, Off-white, Yellow, Yellow-green, Green, Gray, Pink, Brown, Red
- Health notes for each color to help identify potential concerns
- Educational information about what different colors may indicate

### 🤖 AI Health Companion (NEW)
- **Customizable Personality**: Choose your companion's name, tone, communication style, and support level
- **Personality Options**:
  - **Tone**: Warm & Nurturing, Professional, Playful, Gentle, Direct, Encouraging
  - **Style**: Supportive Listener, Educational Expert, Conversational Friend, Concise, Detailed
  - **Support Level**: High Support, Balanced, Information-Focused
- **Custom Description**: Add your own personality traits ("Be encouraging about fitness goals")
- Context-aware responses based on your current cycle day
- Topics covered: periods, cramps, mood, fertility, discharge, self-care, nutrition, and more

### 📈 Statistics
- Average cycle and period length
- Temperature charts with trend analysis
- Complete cycle history visualization
- Days tracked counter

### ⚙️ Settings
- Customizable cycle and period duration
- Use average calculations toggle
- Temperature unit preference
- Notification settings
- Theme options (White, Blue, Flowers, Soft Pink, Aesthetic)

## Project Structure

```
WomensHealthApp/
├── WomensHealthApp/
│   ├── WomensHealthApp.swift      # App entry point
│   ├── ContentView.swift          # Main tab navigation
│   ├── Models.swift               # Data models
│   ├── DataManager.swift          # Data persistence
│   ├── HomeView.swift             # Calendar and home screen
│   ├── LogView.swift              # Daily symptom logging
│   ├── AICompanionManager.swift   # AI logic and responses
│   ├── AICompanionView.swift      # AI chat interface
│   ├── StatisticsView.swift       # Stats and charts
│   ├── SettingsView.swift         # App settings
│   ├── Info.plist                 # App configuration
│   └── Assets.xcassets/           # App assets
└── README.md
```

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS Sonoma or later (for development)

### Creating the Xcode Project

1. **Open Xcode** and select "Create a new Xcode project"

2. **Choose template**: iOS → App

3. **Configure project**:
   - Product Name: `WomensHealthApp`
   - Team: Your development team
   - Organization Identifier: `com.yourname` (or your identifier)
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None (we use UserDefaults)
   - Uncheck "Include Tests" (optional)

4. **Save the project** to a location on your Mac

5. **Copy the Swift files**:
   - Delete the auto-generated `ContentView.swift`
   - Copy all `.swift` files from this package into the project
   - Make sure they're added to the target

6. **Set up Assets**:
   - Replace the Contents.json files in Assets.xcassets
   - Add your app icon (1024x1024 PNG) to AppIcon.appiconset

7. **Configure Info.plist** (if needed):
   - Copy the provided Info.plist or merge the keys

8. **Build and Run**:
   - Select an iPhone simulator or device
   - Press Cmd+R to build and run

### Integrating a Real AI API

The app includes a comprehensive fallback response system, but for production use, you'll want to integrate a real AI API.

#### Option 1: OpenAI API

1. Get an API key from [OpenAI](https://platform.openai.com)

2. In `AICompanionManager.swift`, replace the `generateResponse` function:

```swift
private func generateResponse(userMessage: String, context: String) async -> String {
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "model": "gpt-4",
        "messages": [
            ["role": "system", "content": context],
            ["role": "user", "content": userMessage]
        ],
        "max_tokens": 1000,
        "temperature": 0.7
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return response.choices.first?.message.content ?? "I'm having trouble responding right now."
    } catch {
        return getFallbackResponse(for: userMessage)
    }
}
```

#### Option 2: Anthropic Claude API

```swift
private func generateResponse(userMessage: String, context: String) async -> String {
    let url = URL(string: "https://api.anthropic.com/v1/messages")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("YOUR_API_KEY", forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "model": "claude-3-sonnet-20240229",
        "max_tokens": 1000,
        "system": context,
        "messages": [
            ["role": "user", "content": userMessage]
        ]
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    // ... handle response
}
```

### Adding Push Notifications

1. Enable Push Notifications capability in Xcode
2. Configure in App Store Connect
3. Implement notification scheduling in `DataManager.swift`

### Future Enhancements

- [ ] HealthKit integration
- [ ] Cloud backup with iCloud
- [ ] Apple Watch companion app
- [ ] Widgets for home screen
- [ ] Export data as PDF/CSV
- [ ] Multiple language support
- [ ] Dark mode theme

## Color Scheme

The app uses a soft, calming color palette:

- **Primary**: Coral pink (#ED7891)
- **Secondary**: Light blush (#FAE8ED)
- **Accent**: Dusty mauve (#B57399)
- **Period**: Coral pink
- **Fertile**: Light purple (#D9BFE6)
- **Ovulation**: Purple (#9966B3)

## Privacy

- All data is stored locally on device using UserDefaults
- No data is sent to external servers (unless AI API is integrated)
- No account required
- No tracking or analytics

## License

This project is provided as-is for educational and personal use.

## Support

For questions or issues, please open an issue in this repository.

---

Built with ❤️ using SwiftUI

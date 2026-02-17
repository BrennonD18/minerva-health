//
//  AICompanionManager.swift
//  WomensHealthApp
//

import Foundation
import SwiftUI
import Combine

// MARK: - AI Companion Manager

class AICompanionManager: ObservableObject {
    @Published var isLoading = false
    @Published var personality: AIPersonality
    @Published var conversationHistory: [ChatMessage] = []
    
    private let personalityKey = "aiPersonality"
    
    // Your API endpoint - replace with your actual AI service
    // Options: OpenAI, Anthropic Claude, local LLM, etc.
    private let apiEndpoint = "YOUR_AI_API_ENDPOINT"
    private let apiKey = "YOUR_API_KEY"
    
    init() {
        // Load saved personality
        if let data = UserDefaults.standard.data(forKey: personalityKey),
           let decoded = try? JSONDecoder().decode(AIPersonality.self, from: data) {
            personality = decoded
        } else {
            personality = AIPersonality()
        }
    }
    
    func savePersonality() {
        if let encoded = try? JSONEncoder().encode(personality) {
            UserDefaults.standard.set(encoded, forKey: personalityKey)
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ message: String, cycleContext: CycleContext? = nil) async -> String {
        await MainActor.run {
            isLoading = true
        }
        
        // Add user message to history
        let userMessage = ChatMessage(content: message, isFromUser: true)
        await MainActor.run {
            conversationHistory.append(userMessage)
        }
        
        // Build context-aware prompt
        let contextPrompt = buildContextPrompt(cycleContext: cycleContext)
        
        // In production, this would call your AI API
        // For now, we'll use a smart fallback response system
        let response = await generateResponse(userMessage: message, context: contextPrompt)
        
        let aiMessage = ChatMessage(content: response, isFromUser: false)
        await MainActor.run {
            conversationHistory.append(aiMessage)
            isLoading = false
        }
        
        return response
    }
    
    private func buildContextPrompt(cycleContext: CycleContext?) -> String {
        var context = personality.systemPrompt + "\n\n"
        
        if let cycle = cycleContext {
            context += """
            Current User Context:
            - Day of cycle: \(cycle.currentDay)
            - Days until ovulation: \(cycle.daysToOvulation)
            - Days until next period: \(cycle.daysToNextPeriod)
            - Current phase: \(cycle.phase)
            - Recent symptoms: \(cycle.recentSymptoms.joined(separator: ", "))
            - Recent mood: \(cycle.recentMood ?? "Not logged")
            
            Use this context to provide personalized, relevant advice and support.
            """
        }
        
        return context
    }
    
    // MARK: - Response Generation
    
    private func generateResponse(userMessage: String, context: String) async -> String {
        // This is a comprehensive fallback system
        // In production, replace with actual API call
        
        let lowercasedMessage = userMessage.lowercased()
        
        // Greeting responses
        if containsAny(lowercasedMessage, keywords: ["hello", "hi", "hey", "good morning", "good evening"]) {
            return getGreetingResponse()
        }
        
        // Period-related questions
        if containsAny(lowercasedMessage, keywords: ["period", "menstruation", "bleeding", "flow"]) {
            return getPeriodResponse(message: lowercasedMessage)
        }
        
        // Cramps and pain
        if containsAny(lowercasedMessage, keywords: ["cramp", "pain", "hurt", "ache", "sore"]) {
            return getPainResponse(message: lowercasedMessage)
        }
        
        // PMS and mood
        if containsAny(lowercasedMessage, keywords: ["pms", "mood", "emotional", "irritable", "sad", "anxious", "depressed"]) {
            return getMoodResponse(message: lowercasedMessage)
        }
        
        // Fertility and ovulation
        if containsAny(lowercasedMessage, keywords: ["ovulation", "fertile", "conceive", "pregnancy", "pregnant", "trying"]) {
            return getFertilityResponse(message: lowercasedMessage)
        }
        
        // Discharge questions
        if containsAny(lowercasedMessage, keywords: ["discharge", "mucus", "cervical"]) {
            return getDischargeResponse(message: lowercasedMessage)
        }
        
        // Birth control
        if containsAny(lowercasedMessage, keywords: ["birth control", "contraceptive", "pill", "iud"]) {
            return getBirthControlResponse(message: lowercasedMessage)
        }
        
        // PCOS, endometriosis, and conditions
        if containsAny(lowercasedMessage, keywords: ["pcos", "endometriosis", "fibroids", "cyst"]) {
            return getConditionResponse(message: lowercasedMessage)
        }
        
        // Self-care and wellness
        if containsAny(lowercasedMessage, keywords: ["self-care", "wellness", "relax", "stress", "sleep", "exercise"]) {
            return getSelfCareResponse(message: lowercasedMessage)
        }
        
        // Food and nutrition
        if containsAny(lowercasedMessage, keywords: ["food", "eat", "diet", "nutrition", "cravings"]) {
            return getNutritionResponse(message: lowercasedMessage)
        }
        
        // Default supportive response
        return getDefaultResponse()
    }
    
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
    
    // MARK: - Response Templates
    
    private func getGreetingResponse() -> String {
        let greetings = [
            "Hello! 💕 I'm \(personality.name), your health companion. How are you feeling today? I'm here to chat about anything on your mind – whether it's cycle questions, how you're feeling, or just to talk.",
            "Hey there! ✨ It's so nice to hear from you. I'm \(personality.name), and I'm here to support you. What's going on today? Whether you have health questions or just need someone to listen, I'm all ears.",
            "Hi! 🌸 Welcome! I'm \(personality.name). How can I help you today? Feel free to ask me anything about your cycle, symptoms, or just share how you're doing."
        ]
        return greetings.randomElement() ?? greetings[0]
    }
    
    private func getPeriodResponse(message: String) -> String {
        if message.contains("late") || message.contains("missed") {
            return """
            I understand the concern about a late or missed period. 💭 There are several reasons this can happen:

            • **Stress** - This is one of the most common causes and can delay ovulation
            • **Changes in weight or exercise** - Significant changes can affect your cycle
            • **Travel or schedule changes** - Disruptions to your routine
            • **Hormonal fluctuations** - Completely normal sometimes
            • **Pregnancy** - If there's a possibility, a test would give you clarity

            If your period is more than a week late and this is unusual for you, or if you're experiencing other symptoms, it's worth checking in with a healthcare provider. In the meantime, try to manage stress and take care of yourself. 💕

            Is there anything specific about the situation you'd like to talk through?
            """
        }
        
        if message.contains("heavy") || message.contains("lot of blood") {
            return """
            Dealing with heavy flow can be really challenging. 💪 Here are some things that might help:

            **Managing heavy flow:**
            • Use higher absorbency products or try menstrual cups/discs
            • Consider period underwear as backup protection
            • Stay hydrated and consider iron-rich foods
            • Track your heaviest days to plan accordingly

            **When to see a doctor:**
            • Soaking through a pad/tampon every hour for several hours
            • Bleeding for more than 7 days
            • Passing clots larger than a quarter
            • Feeling very fatigued or lightheaded

            Heavy periods can sometimes indicate conditions like fibroids or hormonal imbalances that are very treatable. Don't hesitate to bring it up with your healthcare provider if this is a pattern for you.

            How are you managing? Is there anything else I can help with?
            """
        }
        
        return """
        Periods can bring up so many questions and experiences! 🌙 

        Everyone's cycle is unique – what's "normal" varies quite a bit from person to person. A typical cycle ranges from 21-35 days, with bleeding lasting 2-7 days.

        What specifically would you like to know more about? I can help with:
        • Understanding cycle phases
        • Managing symptoms
        • What different types of flow might mean
        • When to talk to a healthcare provider

        Just let me know what's on your mind! 💕
        """
    }
    
    private func getPainResponse(message: String) -> String {
        return """
        I'm sorry you're dealing with pain. 💜 Menstrual cramps, while common, can really impact your day. Here are some things that might help:

        **Immediate relief:**
        • Heat therapy - a heating pad or warm bath can relax the muscles
        • Gentle movement - walks, yoga, or stretching
        • Over-the-counter pain relievers (NSAIDs like ibuprofen work well for cramps)
        • Rest when you need it - listen to your body

        **Longer-term strategies:**
        • Regular exercise throughout your cycle
        • Staying hydrated
        • Anti-inflammatory foods (omega-3s, leafy greens)
        • Reducing caffeine and alcohol during your period

        **When to seek help:**
        If your pain is severe, getting worse, interfering significantly with daily life, or not relieved by typical remedies, please talk to a healthcare provider. Conditions like endometriosis are underdiagnosed but very treatable.

        How intense is the pain you're experiencing? And have you found anything that helps, even a little? 🌸
        """
    }
    
    private func getMoodResponse(message: String) -> String {
        return """
        Your feelings are completely valid. 💕 Hormonal fluctuations throughout your cycle can really affect mood, and that doesn't make what you're feeling any less real or important.

        **Understanding the connection:**
        Many people experience mood changes in the days before their period (luteal phase) due to shifts in estrogen and progesterone. This can look like:
        • Feeling more emotional or sensitive
        • Irritability or frustration
        • Anxiety or worry
        • Sadness or feeling low
        • Difficulty concentrating

        **What can help:**
        • Acknowledge your feelings without judgment
        • Gentle exercise (even a short walk helps!)
        • Getting enough sleep
        • Limiting caffeine and sugar
        • Talking to someone you trust
        • Journaling or creative expression
        • Giving yourself permission to rest

        If mood symptoms are significantly impacting your life, interfering with relationships or work, or feel overwhelming, talking to a healthcare provider about PMDD (Premenstrual Dysphoric Disorder) might be helpful.

        How are you feeling right now? I'm here to listen. 🌙
        """
    }
    
    private func getFertilityResponse(message: String) -> String {
        return """
        I'm happy to help you understand more about fertility! 🌟

        **The basics:**
        • Ovulation typically occurs about 14 days before your next period
        • The fertile window is approximately 5 days before ovulation through 1 day after
        • Tracking signs like basal body temperature and cervical mucus can help identify your fertile days

        **Signs of ovulation:**
        • Increased, stretchy cervical mucus (egg-white consistency)
        • Slight rise in basal body temperature after ovulation
        • Some people feel mild cramps or twinges (mittelschmerz)
        • Changes in cervical position
        • Increased libido for some

        **If you're trying to conceive:**
        Understanding your unique cycle is key. This app helps you track patterns over time, which can be really valuable information.

        **If you want to avoid pregnancy:**
        Remember that fertility awareness methods require careful, consistent tracking and have higher failure rates than some other methods. Consider combining with other forms of protection.

        Is there a specific aspect of fertility you'd like to explore further? 💕
        """
    }
    
    private func getDischargeResponse(message: String) -> String {
        return """
        Great question! Vaginal discharge is actually a sign of a healthy reproductive system. 🌸 It changes throughout your cycle:

        **Normal discharge patterns:**
        • **After period:** Minimal or dry
        • **Approaching ovulation:** Increasing, becoming wetter and cloudier
        • **During ovulation:** Clear, stretchy, egg-white texture (most fertile time!)
        • **After ovulation:** Thicker, cloudier, decreasing amount
        • **Before period:** May increase slightly, possibly tinged with brown

        **What's typically normal:**
        • Clear to white or slightly yellow
        • Mild or no odor
        • Not causing itching or irritation

        **When to see a doctor:**
        • Green, gray, or cottage cheese-like texture
        • Strong, fishy, or unpleasant odor
        • Accompanied by itching, burning, or redness
        • Unusual amount (much more or less than usual)

        Tracking your discharge patterns can help you understand your cycle better and notice if something changes. Is there something specific about your discharge that's concerning you? 💕
        """
    }
    
    private func getBirthControlResponse(message: String) -> String {
        return """
        Birth control is a very personal choice, and there are many options! 💊

        I can share general information, but for personalized advice, please talk with a healthcare provider who can consider your full health picture.

        **Common options include:**
        • Hormonal: pills, patches, rings, injections, implants
        • IUDs: hormonal (Mirena, etc.) or copper (Paragard)
        • Barrier methods: condoms, diaphragms
        • Fertility awareness methods
        • Permanent options

        Each has different effectiveness rates, side effects, and considerations. Things to think about include:
        • Your health history
        • Whether you want hormones or not
        • How important "set it and forget it" is to you
        • Future pregnancy plans
        • Period management (some options affect your cycle)

        What aspects of birth control would you like to know more about? Or are you considering making a change? 🌟
        """
    }
    
    private func getConditionResponse(message: String) -> String {
        return """
        I appreciate you bringing this up - these are important topics that deserve attention and support. 💜

        **PCOS (Polycystic Ovary Syndrome):**
        Affects hormone levels and can cause irregular periods, acne, weight changes, and excess hair growth. Very manageable with proper care.

        **Endometriosis:**
        Tissue similar to uterine lining grows outside the uterus, often causing significant pain. Often underdiagnosed but treatments exist.

        **Fibroids:**
        Non-cancerous growths in the uterus that can cause heavy bleeding and discomfort. Very common and usually benign.

        **What I want you to know:**
        • These conditions are more common than people think
        • They're NOT your fault
        • Many effective treatments exist
        • Advocating for yourself with healthcare providers is important
        • Getting a diagnosis can take time, but don't give up

        If you're experiencing symptoms or have been diagnosed, you deserve support and proper care. Would you like to talk more about any of these conditions? I'm here to listen and share what I know. 🌸
        """
    }
    
    private func getSelfCareResponse(message: String) -> String {
        return """
        Self-care is so important, especially when navigating hormonal fluctuations! 🌸 Here are some ideas tailored to your cycle:

        **During your period:**
        • Rest without guilt
        • Warm baths or heating pads
        • Comfort foods (balanced, but comforting)
        • Gentle movement if it feels good
        • Cozy activities: movies, books, naps

        **Follicular phase (after period):**
        • Energy often increases - great time for new projects
        • Try new workouts or activities
        • Social plans

        **Around ovulation:**
        • You might feel your best - use this energy!
        • Great time for challenging tasks

        **Luteal phase (before period):**
        • Wind down gradually
        • Prioritize sleep
        • Reduce stressors where possible
        • Say no to extra commitments
        • Stock up on period supplies and comfort items

        Remember: self-care isn't selfish. Taking care of yourself helps you show up better in all areas of life. What does self-care look like for you? 💕
        """
    }
    
    private func getNutritionResponse(message: String) -> String {
        return """
        Nutrition can really support your cycle! 🥗 Here are some evidence-based tips:

        **Generally supportive foods:**
        • Iron-rich foods (especially during/after your period): leafy greens, beans, lean red meat
        • Omega-3s (anti-inflammatory): fatty fish, walnuts, flaxseed
        • Complex carbs for steady energy
        • Plenty of water

        **During your period:**
        • Focus on iron to replenish what's lost
        • Magnesium-rich foods may help with cramps (dark chocolate counts!)
        • Stay hydrated

        **Managing PMS:**
        • Reducing salt can help with bloating
        • Limiting caffeine and alcohol
        • Calcium and vitamin D may help mood
        • Small, frequent meals for stable blood sugar

        **Cravings:**
        Cravings are normal! Try to honor them while also nourishing yourself. If you're craving chocolate, enjoy some! If you want something salty, have it. Balance, not perfection.

        What's your relationship with food throughout your cycle? Any specific questions? 🌟
        """
    }
    
    private func getDefaultResponse() -> String {
        let responses = [
            "Thank you for sharing that with me. 💕 I'm here to listen and support you. Could you tell me more about what you're experiencing or what questions you have? I want to make sure I can help in the best way possible.",
            "I appreciate you opening up. 🌸 Every experience is valid, and I'm here for whatever you need - whether that's information, a listening ear, or just someone to talk to. What's on your mind?",
            "I'm here for you! ✨ Whether you have specific health questions, want to talk through how you're feeling, or just need some support, I'm happy to help. What would be most helpful right now?"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    // MARK: - Clear History
    
    func clearHistory() {
        conversationHistory.removeAll()
    }
}

// MARK: - Cycle Context

struct CycleContext {
    let currentDay: Int
    let daysToOvulation: Int
    let daysToNextPeriod: Int
    let phase: String
    let recentSymptoms: [String]
    let recentMood: String?
}

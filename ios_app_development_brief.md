# ResilientMe iOS App Development Brief - Swift

## PROJECT OVERVIEW

You are building **ResilientMe**, the first iOS app specifically designed to help Generation Z (ages 18-27) track, understand, and recover from rejection across dating, jobs, and social situations. This app delivers on the promises made on our validation website and fills a gap that no other mental health app addresses.

**Core Mission**: Transform rejection from a source of pain into a tool for building emotional resilience.

---

## APP ARCHITECTURE & TECH STACK

### **Primary Framework**
- **SwiftUI** for modern, declarative UI development
- **iOS 15.0+** minimum deployment target
- **iPhone-first design** with iPad compatibility

### **Backend & Data**
- **Firebase**:
  - Authentication (anonymous and email)
  - Firestore for cloud data sync
  - Cloud Functions for server-side logic
  - Analytics for user behavior tracking
- **Core Data** for offline-first local storage
- **CloudKit** for seamless data sync across devices

### **Additional Frameworks**
```swift
import SwiftUI
import Firebase
import CoreData
import CloudKit
import UserNotifications
import Charts // for iOS 16+ analytics
import LocalAuthentication // for privacy features
import StoreKit // for in-app purchases
```

---

## CORE FEATURES TO BUILD

### **1. INSTANT REJECTION LOGGING**

#### **Quick Log Screen (Primary Feature)**
```swift
// Main logging interface
struct RejectionLogView: View {
    @State private var rejectionType: RejectionType = .dating
    @State private var emotionalImpact: Double = 5.0
    @State private var note: String = ""
    @State private var showCamera = false
    
    enum RejectionType: String, CaseIterable {
        case dating = "💔 Dating"
        case job = "💼 Job"
        case social = "👥 Social"
        case academic = "📚 Academic"
        case other = "😔 Other"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Quick selection buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                    ForEach(RejectionType.allCases, id: \.self) { type in
                        RejectionTypeButton(
                            type: type,
                            isSelected: rejectionType == type,
                            action: { rejectionType = type }
                        )
                    }
                }
                
                // Emotional impact slider
                VStack(alignment: .leading) {
                    Text("How much did this hurt? \(Int(emotionalImpact))/10")
                    Slider(value: $emotionalImpact, in: 1...10, step: 1)
                        .accentColor(.orange)
                }
                
                // Optional note
                TextField("Quick note (optional)", text: $note)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Photo attachment
                Button("Add Screenshot (Optional)") {
                    showCamera = true
                }
                
                // Log button
                Button(action: logRejection) {
                    Text("Log Rejection")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Quick Log")
        }
    }
    
    private func logRejection() {
        let rejection = RejectionEntry(
            type: rejectionType,
            impact: emotionalImpact,
            note: note,
            timestamp: Date(),
            location: getCurrentLocation()
        )
        RejectionManager.shared.saveRejection(rejection)
        
        // Show success feedback
        showSuccessAnimation()
        
        // Clear form
        resetForm()
    }
}
```

#### **Features**:
- **30-second logging**: Large tap targets, minimal required fields
- **Contextual emoji feedback**: Slider shows different emoji faces
- **Photo attachment**: Screenshot capability for rejection texts/emails
- **Auto-location tracking**: Optional location data for pattern analysis
- **Immediate feedback**: Success animation with encouraging message

---

### **2. SMART INSIGHTS DASHBOARD**

#### **Dashboard Screen**
```swift
struct DashboardView: View {
    @StateObject private var analyticsManager = AnalyticsManager()
    @State private var selectedTimeframe: TimeFrame = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Resilience Score Ring
                    ResilienceScoreView(score: analyticsManager.currentResilienceScore)
                    
                    // This Week's Reality
                    WeeklyStatsCard(stats: analyticsManager.weeklyStats)
                    
                    // Pattern Recognition Alerts
                    if !analyticsManager.patterns.isEmpty {
                        PatternAlertsCard(patterns: analyticsManager.patterns)
                    }
                    
                    // Recovery Time Trends
                    RecoveryTrendsChart(data: analyticsManager.recoveryData)
                    
                    // Streak Counters
                    StreakCounterCard(streaks: analyticsManager.currentStreaks)
                }
                .padding()
            }
            .navigationTitle("Your Resilience")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(TimeFrame.allCases, id: \.self) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
}

struct ResilienceScoreView: View {
    let score: Double
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green], 
                            startPoint: .leading, 
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: score)
                
                Text("\(Int(score))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Text("Resilience Score")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(getResilienceMessage(for: score))
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func getResilienceMessage(for score: Double) -> String {
        switch score {
        case 80...100: return "You're bouncing back stronger! 🚀"
        case 60...79: return "Building solid resilience 💪"
        case 40...59: return "Making progress, keep going 📈"
        case 20...39: return "Every step counts 🌱"
        default: return "You're taking the first step 🌟"
        }
    }
}
```

#### **Smart Pattern Recognition**
```swift
class PatternAnalyzer: ObservableObject {
    static let shared = PatternAnalyzer()
    
    func analyzePatterns(for rejections: [RejectionEntry]) -> [Pattern] {
        var patterns: [Pattern] = []
        
        // Frequency patterns
        if let ghostingPattern = detectGhostingPattern(rejections) {
            patterns.append(ghostingPattern)
        }
        
        // Timing patterns
        if let dayPattern = detectDayOfWeekPattern(rejections) {
            patterns.append(dayPattern)
        }
        
        // Recovery patterns
        if let recoveryPattern = detectRecoveryImprovement(rejections) {
            patterns.append(recoveryPattern)
        }
        
        return patterns
    }
    
    private func detectGhostingPattern(_ rejections: [RejectionEntry]) -> Pattern? {
        let datingRejections = rejections.filter { $0.type == .dating }
        let ghostingCount = datingRejections.filter { $0.note.lowercased().contains("ghost") }.count
        
        if ghostingCount >= 3 && ghostingCount > datingRejections.count / 2 {
            return Pattern(
                title: "Ghosting Pattern Detected",
                description: "You've been ghosted \(ghostingCount) times this month",
                insight: "This is about their communication style, not your worth",
                actionable: "Try apps that require more investment upfront"
            )
        }
        return nil
    }
}
```

---

### **3. CONTEXTUAL RECOVERY TOOLS**

#### **Recovery Hub (Dynamic Based on Last Rejection)**
```swift
struct RecoveryHubView: View {
    @StateObject private var recoveryManager = RecoveryManager()
    let lastRejection: RejectionEntry?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let rejection = lastRejection {
                        // Context-specific recovery plan
                        RecoveryPlanCard(for: rejection.type)
                        
                        // Quick recovery actions
                        QuickRecoveryActions(for: rejection.type)
                        
                        // Progress tracking
                        RecoveryProgressView(rejection: rejection)
                    }
                    
                    // General resilience tools
                    ResilienceToolsGrid()
                }
                .padding()
            }
            .navigationTitle("Recovery Hub")
        }
    }
}

struct RecoveryPlanCard: View {
    let rejectionType: RejectionType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(getRecoveryTitle(for: rejectionType))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(getRecoveryDescription(for: rejectionType))
                .font(.body)
                .foregroundColor(.secondary)
            
            // 5-minute action plan
            VStack(alignment: .leading, spacing: 8) {
                Text("5-Minute Recovery Plan:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(getRecoverySteps(for: rejectionType), id: \.self) { step in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text(step)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getRecoveryTitle(for type: RejectionType) -> String {
        switch type {
        case .dating: return "Ghosted Again? You're Not Alone"
        case .job: return "Another 'No'? Let's Rebuild Your Confidence"
        case .social: return "Awkward Moment? Everyone Has Them"
        case .academic: return "Rejection Builds Character"
        case .other: return "This Too Shall Pass"
        }
    }
    
    private func getRecoverySteps(for type: RejectionType) -> [String] {
        switch type {
        case .dating:
            return [
                "Take 3 deep breaths - this is about them, not you",
                "Remember: 77% of Gen Z have ghosted someone",
                "Text a friend who makes you laugh",
                "Do one thing that makes you feel good about yourself",
                "Remind yourself of your worth - write down 3 good qualities"
            ]
        case .job:
            return [
                "Remember: average job gets 240+ applications",
                "This rejection brings you closer to the right fit",
                "Update your application tracker",
                "Apply to 2 more positions today",
                "Celebrate that you're putting yourself out there"
            ]
        default:
            return [
                "Acknowledge the feeling without judgment",
                "Put it in perspective - is this important in a year?",
                "Do something kind for yourself",
                "Connect with someone who supports you",
                "Focus on what you can control going forward"
            ]
        }
    }
}
```

#### **Response Templates Feature**
```swift
struct ResponseTemplatesView: View {
    let rejectionType: RejectionType
    @State private var selectedTemplate: ResponseTemplate?
    
    var body: some View {
        List {
            ForEach(getTemplates(for: rejectionType), id: \.id) { template in
                ResponseTemplateCard(
                    template: template,
                    onSelect: { selectedTemplate = template }
                )
            }
        }
        .navigationTitle("Response Templates")
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
    }
    
    private func getTemplates(for type: RejectionType) -> [ResponseTemplate] {
        switch type {
        case .dating:
            return [
                ResponseTemplate(
                    title: "After Being Ghosted",
                    scenario: "When someone stops responding completely",
                    template: "Hey [Name], I noticed we haven't connected in a while. No worries if you're not interested - I appreciate the good conversations we had. Take care!",
                    tone: "Graceful exit"
                ),
                ResponseTemplate(
                    title: "After Direct Rejection",
                    scenario: "When someone says they're not interested",
                    template: "Thanks for being honest with me. I respect that and wish you the best!",
                    tone: "Mature response"
                )
            ]
        case .job:
            return [
                ResponseTemplate(
                    title: "Following Up After Silence",
                    scenario: "When you haven't heard back about an application",
                    template: "Hi [Name], I wanted to follow up on my application for [Position]. I'm still very interested and would love to discuss how my skills could contribute to [Company]. Thank you for your time.",
                    tone: "Professional persistence"
                ),
                ResponseTemplate(
                    title: "Responding to Rejection",
                    scenario: "When you receive a rejection email",
                    template: "Thank you for letting me know. While I'm disappointed, I appreciate the opportunity to interview. If any similar positions open up, I'd love to be considered. Best wishes to your team.",
                    tone: "Professional grace"
                )
            ]
        default: return []
        }
    }
}
```

---

### **4. PROGRESSIVE RESILIENCE CHALLENGES**

#### **Daily Challenge System**
```swift
struct ChallengeView: View {
    @StateObject private var challengeManager = ChallengeManager()
    @State private var currentChallenge: Challenge?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let challenge = currentChallenge {
                    // Current challenge card
                    ChallengeCard(challenge: challenge)
                    
                    // Progress indicator
                    ChallengeProgressView(challenge: challenge)
                    
                    // Action buttons
                    ChallengeActionButtons(
                        challenge: challenge,
                        onComplete: completeChallenge,
                        onSkip: skipChallenge
                    )
                } else {
                    // Loading or no challenge state
                    Text("Generating your personalized challenge...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak display
                StreakDisplayView(streak: challengeManager.currentStreak)
            }
            .padding()
            .navigationTitle("Today's Challenge")
            .onAppear {
                loadTodaysChallenge()
            }
        }
    }
    
    private func loadTodaysChallenge() {
        currentChallenge = challengeManager.getTodaysChallenge()
    }
    
    private func completeChallenge() {
        guard let challenge = currentChallenge else { return }
        challengeManager.markCompleted(challenge)
        
        // Show celebration
        showCelebrationAnimation()
        
        // Update resilience score
        ResilienceScoreManager.shared.addPoints(for: challenge.difficulty)
    }
}

class ChallengeManager: ObservableObject {
    @Published var currentStreak: Int = 0
    private let userDefaults = UserDefaults.standard
    
    func getTodaysChallenge() -> Challenge? {
        // Get user's recent rejection patterns
        let recentRejections = RejectionManager.shared.getRecentRejections(days: 7)
        let resilienceLevel = ResilienceScoreManager.shared.getCurrentLevel()
        
        // Generate personalized challenge
        return generateChallenge(
            basedOn: recentRejections, 
            level: resilienceLevel
        )
    }
    
    private func generateChallenge(
        basedOn rejections: [RejectionEntry], 
        level: ResilienceLevel
    ) -> Challenge {
        
        let mostCommonType = rejections.mostCommon(\.type) ?? .social
        
        switch (mostCommonType, level) {
        case (.dating, .beginner):
            return Challenge(
                title: "Small Social Step",
                description: "Start a conversation with one new person today",
                type: .social,
                difficulty: .easy,
                points: 10,
                timeEstimate: "5 minutes"
            )
            
        case (.dating, .intermediate):
            return Challenge(
                title: "Confidence Builder",
                description: "Ask someone for their number or social media",
                type: .dating,
                difficulty: .medium,
                points: 25,
                timeEstimate: "10 minutes"
            )
            
        case (.job, .beginner):
            return Challenge(
                title: "Application Momentum",
                description: "Apply to 3 jobs today, focus on quality applications",
                type: .career,
                difficulty: .easy,
                points: 15,
                timeEstimate: "30 minutes"
            )
            
        case (.job, .intermediate):
            return Challenge(
                title: "Network Expansion",
                description: "Reach out to 2 people in your desired field on LinkedIn",
                type: .career,
                difficulty: .medium,
                points: 30,
                timeEstimate: "20 minutes"
            )
            
        default:
            return Challenge(
                title: "Self-Care Check",
                description: "Do one thing today that makes you feel good about yourself",
                type: .selfCare,
                difficulty: .easy,
                points: 10,
                timeEstimate: "15 minutes"
            )
        }
    }
}
```

---

### **5. ANONYMOUS COMMUNITY**

#### **Community Feed**
```swift
struct CommunityView: View {
    @StateObject private var communityManager = CommunityManager()
    @State private var selectedFilter: RejectionType? = nil
    @State private var showingSubmissionSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterPill(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        ForEach(RejectionType.allCases, id: \.self) { type in
                            FilterPill(
                                title: type.rawValue,
                                isSelected: selectedFilter == type,
                                action: { selectedFilter = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Story feed
                List {
                    ForEach(communityManager.getStories(filter: selectedFilter), id: \.id) { story in
                        CommunityStoryCard(
                            story: story,
                            onReact: { reaction in
                                communityManager.addReaction(to: story, reaction: reaction)
                            }
                        )
                    }
                }
                .refreshable {
                    await communityManager.loadStories()
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        showingSubmissionSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingSubmissionSheet) {
                StorySubmissionView()
            }
        }
    }
}

struct CommunityStoryCard: View {
    let story: CommunityStory
    let onReact: (Reaction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Story metadata
            HStack {
                Text(story.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                Text(story.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Story content
            Text(story.content)
                .font(.body)
                .lineLimit(nil)
            
            // Reaction bar
            HStack(spacing: 16) {
                ForEach(Reaction.allCases, id: \.self) { reaction in
                    ReactionButton(
                        reaction: reaction,
                        count: story.reactions[reaction] ?? 0,
                        isActive: story.userReaction == reaction,
                        action: { onReact(reaction) }
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .listRowSeparator(.hidden)
    }
}

enum Reaction: String, CaseIterable {
    case support = "💪"  // You got this
    case relate = "😔"    // I feel this
    case celebrate = "🎉" // Proud of you
    case hug = "🫂"       // Virtual hug
}
```

---

### **6. DATA PERSISTENCE & SYNC**

#### **Core Data Model**
```swift
// RejectionEntry+CoreDataClass.swift
@objc(RejectionEntry)
public class RejectionEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var emotionalImpact: Double
    @NSManaged public var note: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var location: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var isRecovered: Bool
    @NSManaged public var recoveryTime: TimeInterval
}

// Data Manager
class RejectionDataManager: ObservableObject {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ResilientMe")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveRejection(_ rejection: RejectionEntry) {
        do {
            try context.save()
            
            // Sync to Firebase
            FirebaseManager.shared.syncRejection(rejection)
            
            // Update analytics
            AnalyticsManager.shared.trackRejectionLogged(type: rejection.type)
            
        } catch {
            print("Failed to save rejection: \(error)")
        }
    }
}
```

---

### **7. NOTIFICATIONS & REMINDERS**

#### **Smart Notification System**
```swift
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestPermission()
    }
    
    func scheduleSmartReminders() {
        // Daily check-in reminder
        scheduleDailyCheckIn()
        
        // Challenge reminder
        scheduleChallengeReminder()
        
        // Recovery follow-up
        scheduleRecoveryFollowUp()
    }
    
    private func scheduleDailyCheckIn() {
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling today?"
        content.body = "Take 30 seconds to check in with yourself"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-checkin",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleRecoveryFollowUp() {
        // Schedule follow-up notification 24 hours after logging a high-impact rejection
        let recentHighImpactRejections = RejectionManager.shared.getRecentHighImpactRejections()
        
        for rejection in recentHighImpactRejections {
            let content = UNMutableNotificationContent()
            content.title = "How are you doing?"
            content.body = "Yesterday was tough. You're stronger than you know."
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 hours
            let request = UNNotificationRequest(
                identifier: "recovery-followup-\(rejection.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
```

---

### **8. PRIVACY & SECURITY FEATURES**

#### **Privacy-First Design**
```swift
class PrivacyManager: ObservableObject {
    @AppStorage("biometric_lock") private var biometricLockEnabled: Bool = false
    @AppStorage("anonymous_mode") private var anonymousMode: Bool = true
    
    func enableBiometricLock() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.biometryAny, error: &error) {
            biometricLockEnabled = true
        }
    }
    
    func authenticateUser() async -> Bool {
        guard biometricLockEnabled else { return true }
        
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        do {
            let result = try await context.evaluatePolicy(
                .biometryAny,
                localizedReason: "Access your rejection data securely"
            )
            return result
        } catch {
            return false
        }
    }
    
    func anonymizeData() {
        // Remove identifying information when sharing community stories
        // Encrypt sensitive data locally
        // Provide data export/deletion options
    }
}
```

---

## USER INTERFACE GUIDELINES

### **Design System**
```swift
// Colors
extension Color {
    static let resilientPrimary = Color("ResilientPrimary") // Deep blue
    static let resilientSecondary = Color("ResilientSecondary") // Orange accent
    static let resilientBackground = Color("ResilientBackground") // True black
    static let resilientSurface = Color("ResilientSurface") // Dark gray
}

// Typography
extension Font {
    static let resilientTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let resilientHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let resilientBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let resilientCaption = Font.system(size: 12, weight: .medium, design: .rounded)
}

// Components
struct ResilientButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.resilientHeadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(12)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .resilientSecondary
        case .secondary: return .resilientSurface
        case .destructive: return .red
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
}
```

---

## IMPLEMENTATION PRIORITIES

### **Phase 1: Core MVP (Weeks 1-2)**
1. **Basic rejection logging** with types and impact rating
2. **Simple dashboard** showing count and basic stats
3. **Core Data setup** for local storage
4. **Basic UI** with dark theme

### **Phase 2: Smart Features (Weeks 3-4)**
1. **Pattern recognition** for basic insights
2. **Recovery tools** with contextual content
3. **Daily challenges** system
4. **Push notifications**

### **Phase 3: Community & Polish (Weeks 5-6)**
1. **Anonymous community** features
2. **Advanced analytics** and charts
3. **Biometric security**
4. **App Store optimization**

---

## TECHNICAL REQUIREMENTS

### **Performance Standards**
- **App launch time**: Under 2 seconds cold start
- **Logging interaction**: Complete in under 30 seconds
- **Offline functionality**: Full logging capability without internet
- **Battery optimization**: Minimal background processing
- **Memory usage**: Stay under 50MB average

### **Accessibility Requirements**
- **VoiceOver support** for all interactive elements
- **Dynamic Type** support for text scaling
- **High contrast** mode compatibility
- **Voice Control** navigation support
- **Minimum touch targets** of 44x44 points

### **Testing Strategy**
```swift
// Unit tests for core functionality
class RejectionManagerTests: XCTestCase {
    func testRejectionLogging() {
        // Test rejection creation and storage
    }
    
    func testPatternRecognition() {
        // Test pattern detection algorithms
    }
    
    func testResilienceScoreCalculation() {
        // Test score calculation logic
    }
}

// UI tests for critical flows
class RejectionLoggingUITests: XCTestCase {
    func testQuickLoggingFlow() {
        // Test the 30-secon
import SwiftUI

struct CommunityView: View {
    @StateObject private var manager = CommunityManager()
    @State private var selectedFilter: RejectionType? = nil
    @State private var showingSubmission = false

    var body: some View {
        NavigationView {
            AuthGate {
                VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterPill(title: "All", isSelected: selectedFilter == nil) { selectedFilter = nil }
                            .accessibilityLabel("Filter All")
                        ForEach(RejectionType.allCases) { type in
                            FilterPill(title: type.displayTitle, isSelected: selectedFilter == type) { selectedFilter = type }
                                .accessibilityLabel("Filter \(type.displayTitle)")
                        }
                    }
                    .padding(.horizontal)
                }

                if manager.isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<6) { _ in SkeletonView(height: 72, cornerRadius: 12) }
                    }.padding()
                } else if manager.getStories(filter: selectedFilter).isEmpty {
                    VStack(spacing: 12) {
                        Text("No stories yet.").font(.resilientHeadline)
                        Text("Share your first story. Someone will relate.").font(.resilientBody).foregroundColor(.secondary)
                        ResilientButton(title: "Share a story", style: .primary) { showingSubmission = true }
                    }
                    .resilientCard()
                    .padding()
                } else {
                    List {
                        ForEach(manager.getStories(filter: selectedFilter)) { story in
                            CommunityStoryCard(story: story) { reaction in
                                // optimistic UI
                                Haptics.light()
                                manager.addReaction(to: story, reaction: reaction)
                                AnalyticsManager.trackReactionAdd(reaction)
                            }
                            .swipeActions {
                                Button(role: .destructive) { manager.report(story: story) } label: { Label("Report", systemImage: "exclamationmark.triangle") }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await manager.loadStories() }
                }
                }
                .navigationTitle("Community")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Share") { showingSubmission = true } } }
                .sheet(isPresented: $showingSubmission) { StorySubmissionView(onSubmit: { type, text in
                    Task { try? await manager.submitStory(type: type, content: text); AnalyticsManager.trackCommunityPost(); await manager.loadStories() }
                }) }
                .onAppear { AnalyticsManager.trackScreenView("Community"); Task { await manager.loadStories() } }
            }
        }
        .background(Color.resilientBackground.ignoresSafeArea())
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.resilientPrimary.opacity(0.2) : Color(.systemGray6))
                .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

struct CommunityStoryCard: View {
    let story: CommunityStory
    let onReact: (Reaction) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(story.type.displayTitle).font(.caption)
                Spacer()
                Text(story.timeAgo).font(.caption).foregroundColor(.secondary)
            }
            Text(story.content).font(.body)
            HStack(spacing: 12) {
                ForEach(Reaction.allCases, id: \.self) { r in
                    Button(action: { onReact(r) }) {
                        HStack(spacing: 4) {
                            Text(r.rawValue)
                            Text("\(story.reactions[r] ?? 0)").font(.caption)
                        }
                    }
                    .accessibilityLabel(Text("Add reaction \(r.accessibilityLabel)"))
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

struct StorySubmissionView: View {
    var onSubmit: (RejectionType, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var type: RejectionType = .dating
    @State private var text: String = ""

    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $type) { ForEach(RejectionType.allCases) { Text($0.displayTitle).tag($0) } }
                TextEditor(text: $text).frame(height: 160).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray5)))
            }
            .navigationTitle("Share Your Story")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Post") { onSubmit(type, text); dismiss() } .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}



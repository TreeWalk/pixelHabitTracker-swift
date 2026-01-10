import SwiftUI
import UIKit

struct QuestsView: View {
    @EnvironmentObject var questStore: SwiftDataQuestStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showAddSheet = false
    @State private var showLogSheet = false
    @State private var isCompletedExpanded = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header
                        headerSection
                        
                        Rectangle()
                            .fill(Color("PixelAccent"))
                            .frame(height: 4)
                            .padding(.horizontal)
                        
                        // Active Quests
                        if !questStore.activeQuests.isEmpty {
                            activeQuestsSection
                        }
                        
                        // Completed Quests
                        if !questStore.completedQuests.isEmpty {
                            completedQuestsSection
                        }
                        
                        // Empty State
                        if questStore.quests.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // FAB
                fabButton
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddQuestSheet()
        }
        .sheet(isPresented: $showLogSheet) {
            QuestLogView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("quests_title".localized)
                    .font(.pixel(28))
                    .foregroundColor(Color("PixelBorder"))
                
                Text("Lvl \(questStore.currentLevel). \(questStore.currentTitle)")
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelAccent"))
            }
            
            Spacer()
            
            Button(action: { showLogSheet = true }) {
                VStack(spacing: 2) {
                    Image(systemName: "scroll.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("LOG")
                        .font(.pixel(12))
                }
                .foregroundColor(Color("PixelBorder"))
                .frame(width: 60, height: 50)
                .background(Color("PixelAccent"))
                .pixelBorderSmall()
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Active Quests Section
    private var activeQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quest_active".localized)
                .font(.pixel(16))
                .foregroundColor(Color("PixelAccent"))
                .padding(.horizontal)
            
            ForEach(questStore.activeQuests) { quest in
                SimpleQuestCard(quest: quest) {
                    toggleQuestWithFeedback(quest)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Completed Quests Section
    private var completedQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isCompletedExpanded.toggle()
                }
            }) {
                HStack {
                    Text("quest_completed_section".localized)
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelGreen"))
                    
                    Text("(\(questStore.completedQuests.count))")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelGreen").opacity(0.7))
                    
                    Spacer()
                    
                    Image(systemName: isCompletedExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color("PixelGreen"))
                }
            }
            .padding(.horizontal)
            
            if isCompletedExpanded {
                ForEach(questStore.completedQuests) { quest in
                    SimpleQuestCard(quest: quest, isCompleted: true) {
                        toggleQuestWithFeedback(quest)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 48))
                .foregroundColor(Color("PixelAccent").opacity(0.5))
            Text("quest_empty".localized)
                .font(.pixel(16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - FAB Button
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color("PixelBlue"))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color("PixelBorder"), lineWidth: 4)
                        )
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Toggle with Feedback
    private func toggleQuestWithFeedback(_ quest: QuestData) {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        questStore.toggleQuest(quest)
    }
}

// MARK: - Simple Quest Card (Optimized)
struct SimpleQuestCard: View {
    let quest: QuestData
    var isCompleted: Bool = false
    let onToggle: () -> Void
    
    private var questType: Quest.QuestType {
        if let type = Quest.QuestType(rawValue: quest.type) {
            return type
        }
        let capitalized = quest.type.prefix(1).uppercased() + quest.type.dropFirst().lowercased()
        return Quest.QuestType(rawValue: capitalized) ?? .health
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Color bar
                Rectangle()
                    .fill(Color(questType.color))
                    .frame(width: 6)
                
                // Checkbox
                ZStack {
                    Rectangle()
                        .fill(isCompleted ? Color("PixelGreen") : .white)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Rectangle()
                                .stroke(Color("PixelBorder"), lineWidth: 3)
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .strikethrough(isCompleted)
                    
                    HStack(spacing: 8) {
                        Text(quest.type.uppercased())
                            .font(.pixel(11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(questType.color).opacity(0.2))
                        
                        Text("+\(quest.xp) XP")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelAccent"))
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .padding(.leading, -10)
            .background(isCompleted ? Color("PixelGreen").opacity(0.1) : .white)
            .pixelBorderSmall(color: isCompleted ? Color("PixelGreen") : Color("PixelBorder"))
        }
        .buttonStyle(.plain)
        .opacity(isCompleted ? 0.8 : 1)
    }
}

// MARK: - Add Quest Sheet
struct AddQuestSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questStore: SwiftDataQuestStore
    @State private var title = ""
    @State private var xp = 50
    @State private var type: Quest.QuestType = .health
    @State private var recurrence: Quest.QuestRecurrence = .daily
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("quest_title_label".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            TextField("quest_title_placeholder".localized, text: $title)
                                .font(.pixel(18))
                                .padding(16)
                                .background(.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("PixelBorder"), lineWidth: 3)
                                )
                        }
                        
                        // Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("quest_type_label".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                ForEach(Quest.QuestType.allCases, id: \.self) { questType in
                                    TypeButton(type: questType, isSelected: type == questType) {
                                        type = questType
                                    }
                                }
                            }
                        }
                        
                        // XP Selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("quest_xp_reward".localized)
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelAccent"))
                                Spacer()
                                Text("+\(xp) XP")
                                    .font(.pixel(18))
                                    .foregroundColor(Color("PixelAccent"))
                            }
                            
                            HStack(spacing: 6) {
                                ForEach([25, 50, 75, 100, 150, 200], id: \.self) { value in
                                    Button(action: { xp = value }) {
                                        Text("\(value)")
                                            .font(.pixel(14))
                                            .foregroundColor(xp == value ? .white : Color("PixelBorder"))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(xp == value ? Color("PixelAccent") : .white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color("PixelBorder"), lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Recurrence Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("quest_recurrence_label".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            HStack(spacing: 6) {
                                ForEach(Quest.QuestRecurrence.allCases, id: \.self) { rec in
                                    Button(action: { recurrence = rec }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: rec.icon)
                                                .font(.system(size: 16))
                                            Text(rec.displayName)
                                                .font(.pixel(10))
                                        }
                                        .foregroundColor(recurrence == rec ? .white : Color("PixelBorder"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(recurrence == rec ? Color("PixelBlue") : .white)
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color("PixelBorder"), lineWidth: 2)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Create Button
                VStack {
                    Spacer()
                    Button(action: createQuest) {
                        Text("quest_create".localized)
                            .font(.pixel(20))
                            .foregroundColor(title.isEmpty ? .gray : Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(title.isEmpty ? Color("PixelAccent").opacity(0.5) : Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                    .disabled(title.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("quest_new".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
    }
    
    private func createQuest() {
        questStore.addQuest(title: title, xp: xp, type: type.rawValue, recurrence: recurrence.rawValue)
        dismiss()
    }
}

// MARK: - Type Button
struct TypeButton: View {
    let type: Quest.QuestType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : Color(type.color))
                Text(type.rawValue)
                    .font(.pixel(10))
                    .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(type.color) : .white)
            .overlay(
                Rectangle()
                    .stroke(Color(type.color), lineWidth: 2)
            )
        }
    }
}

#Preview {
    QuestsView()
        .environmentObject(SwiftDataQuestStore())
}

import SwiftUI
import UIKit

struct QuestsView: View {
    @EnvironmentObject var questStore: QuestStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showAddSheet = false
    @State private var showLogSheet = false
    
    // 撤销机制状态
    @State private var pendingQuestId: Int? = nil
    @State private var pendingQuestTitle: String = ""
    @State private var undoCountdown: Int = 3
    @State private var undoTimer: Timer? = nil
    
    // 已完成区域折叠状态
    @State private var isCompletedExpanded = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("quests_title".localized)
                                    .font(.pixel(28))
                                    .foregroundColor(Color("PixelBorder"))
                                    
                                Text("Lvl 5. Freelancer")
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
                        
                        Rectangle()
                            .fill(Color("PixelAccent"))
                            .frame(height: 4)
                            .padding(.horizontal)
                        
                        // MARK: - 进行中任务区
                        if !questStore.activeQuests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("quest_active".localized)
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelAccent"))
                                    .padding(.horizontal)
                                
                                ForEach(questStore.activeQuests) { quest in
                                    QuestCardView(
                                        quest: quest,
                                        isPending: pendingQuestId == quest.id
                                    ) {
                                        startPendingCompletion(quest: quest)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // MARK: - 已完成任务区
                        if !questStore.completedQuests.isEmpty {
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
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("PixelGreen"))
                                    }
                                    .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                
                                if isCompletedExpanded {
                                    ForEach(questStore.completedQuests) { quest in
                                        QuestCardView(
                                            quest: quest,
                                            isPending: false
                                        ) {
                                            // 点击已完成任务可取消完成
                                            Task {
                                                await questStore.toggleQuest(id: quest.id)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                            }
                        }
                        
                        // 空状态
                        if questStore.quests.isEmpty {
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
                    }
                    .padding(.bottom, 100)
                }
                
                // FAB
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
                        .padding(.bottom, pendingQuestId != nil ? 80 : 24)
                    }
                }
                
                // MARK: - 撤销 Toast
                if pendingQuestId != nil {
                    VStack {
                        Spacer()
                        UndoToast(
                            questTitle: pendingQuestTitle,
                            countdown: undoCountdown,
                            onUndo: cancelPendingCompletion
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.3), value: pendingQuestId)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddQuestSheet()
        }
        .sheet(isPresented: $showLogSheet) {
            QuestLogSheet()
        }
    }
    
    // MARK: - 撤销机制
    private func startPendingCompletion(quest: Quest) {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 如果已有待确认任务，先取消
        cancelPendingCompletion()
        
        pendingQuestId = quest.id
        pendingQuestTitle = quest.title
        undoCountdown = 3
        
        // 启动倒计时
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if undoCountdown > 1 {
                undoCountdown -= 1
            } else {
                confirmCompletion()
            }
        }
    }
    
    private func cancelPendingCompletion() {
        undoTimer?.invalidate()
        undoTimer = nil
        
        withAnimation(.spring(response: 0.3)) {
            pendingQuestId = nil
            pendingQuestTitle = ""
        }
    }
    
    private func confirmCompletion() {
        guard let questId = pendingQuestId else { return }
        
        undoTimer?.invalidate()
        undoTimer = nil
        
        // 成功完成的触觉反馈
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        Task {
            await questStore.toggleQuest(id: questId)
        }
        
        withAnimation(.spring(response: 0.3)) {
            pendingQuestId = nil
            pendingQuestTitle = ""
        }
    }
}

// MARK: - 撤销 Toast
struct UndoToast: View {
    let questTitle: String
    let countdown: Int
    let onUndo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 倒计时圆环
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: CGFloat(countdown) / 3.0)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: countdown)
                
                Text("\(countdown)")
                    .font(.pixel(14))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("quest_completing".localized)
                    .font(.pixel(12))
                    .foregroundColor(.white.opacity(0.8))
                Text(questTitle)
                    .font(.pixel(16))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onUndo) {
                Text("quest_undo".localized)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelAccent"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background(Color("PixelBorder"))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

struct QuestCardView: View {
    let quest: Quest
    var isPending: Bool = false
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // 类型颜色条
                Rectangle()
                    .fill(Color(quest.type.color))
                    .frame(width: 6)
                
                // Checkbox
                ZStack {
                    Rectangle()
                        .fill(isPending ? Color("PixelAccent") : (quest.completed ? Color("PixelGreen") : .white))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Rectangle()
                                .stroke(Color("PixelBorder"), lineWidth: 4)
                        )
                    
                    if quest.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else if isPending {
                        // 待确认状态显示时钟图标
                        Image(systemName: "clock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color("PixelBorder"))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.pixel(20))
                        .foregroundColor(Color("PixelBorder"))
                        .strikethrough(quest.completed)
                    
                    HStack(spacing: 8) {
                        Text(quest.type.rawValue.uppercased())
                            .font(.pixel(12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(quest.type.color).opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .stroke(Color(quest.type.color).opacity(0.5), lineWidth: 2)
                            )
                        
                        // 周期标签
                        HStack(spacing: 3) {
                            Image(systemName: quest.recurrence.icon)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary)
                        
                        Text("+\(quest.xp) XP")
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelAccent"))
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .padding(.leading, -12) // 补偿颜色条的间距
            .background(isPending ? Color("PixelAccent").opacity(0.15) : (quest.completed ? Color("PixelGreen").opacity(0.1) : .white))
            .pixelBorderSmall(color: isPending ? Color("PixelAccent") : (quest.completed ? Color("PixelGreen") : Color("PixelBorder")))
            .pixelCorners(color: isPending ? Color("PixelAccent") : (quest.completed ? Color("PixelGreen") : Color("PixelBorder")))
        }
        .buttonStyle(.plain)
        .opacity(quest.completed ? 0.8 : 1)
        .scaleEffect(isPending ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPending)
    }
}

struct AddQuestSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questStore: QuestStore
    @State private var title = ""
    @State private var xp = 50
    @State private var type: Quest.QuestType = .health
    @State private var recurrence: Quest.QuestRecurrence = .daily
    
    // 触觉反馈
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - 任务标题
                        VStack(alignment: .leading, spacing: 8) {
                            Label("quest_title_label".localized, systemImage: "pencil")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            TextField("quest_title_placeholder".localized, text: $title)
                                .font(.pixel(18))
                                .padding(16)
                                .background(.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(title.isEmpty ? Color("PixelBorder").opacity(0.3) : Color("PixelAccent"), lineWidth: 3)
                                )
                                .animation(.easeInOut(duration: 0.2), value: title.isEmpty)
                        }
                        
                        // MARK: - 任务类型选择
                        VStack(alignment: .leading, spacing: 12) {
                            Label("quest_type_label".localized, systemImage: "tag.fill")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                ForEach(Quest.QuestType.allCases, id: \.self) { questType in
                                    QuestTypeButton(
                                        type: questType,
                                        isSelected: type == questType
                                    ) {
                                        selectionFeedback.selectionChanged()
                                        withAnimation(.spring(response: 0.3)) {
                                            type = questType
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - XP 奖励选择
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("quest_xp_reward".localized, systemImage: "star.fill")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelAccent"))
                                
                                Spacer()
                                
                                Text("+\(xp) XP")
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelAccent"))
                            }
                            
                            // XP 选择按钮组
                            HStack(spacing: 8) {
                                ForEach([25, 50, 75, 100, 150, 200], id: \.self) { value in
                                    XPButton(
                                        value: value,
                                        isSelected: xp == value
                                    ) {
                                        selectionFeedback.selectionChanged()
                                        withAnimation(.spring(response: 0.3)) {
                                            xp = value
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - 任务周期选择
                        VStack(alignment: .leading, spacing: 12) {
                            Label("quest_recurrence_label".localized, systemImage: "repeat")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            HStack(spacing: 8) {
                                ForEach(Quest.QuestRecurrence.allCases, id: \.self) { rec in
                                    RecurrenceButton(
                                        recurrence: rec,
                                        isSelected: recurrence == rec
                                    ) {
                                        selectionFeedback.selectionChanged()
                                        withAnimation(.spring(response: 0.3)) {
                                            recurrence = rec
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - 预览卡片
                        if !title.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("quest_preview".localized)
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelAccent"))
                                
                                HStack(spacing: 12) {
                                    Rectangle()
                                        .fill(Color(type.color))
                                        .frame(width: 6)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(.pixel(18))
                                            .foregroundColor(Color("PixelBorder"))
                                            .lineLimit(1)
                                        
                                        HStack(spacing: 8) {
                                            Text(type.rawValue.uppercased())
                                                .font(.pixel(11))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(type.color).opacity(0.2))
                                            
                                            // 周期标签
                                            HStack(spacing: 4) {
                                                Image(systemName: recurrence.icon)
                                                    .font(.system(size: 10))
                                                Text(recurrence.displayName)
                                                    .font(.pixel(11))
                                            }
                                            .foregroundColor(.secondary)
                                            
                                            Text("+\(xp) XP")
                                                .font(.pixel(14))
                                                .foregroundColor(Color("PixelAccent"))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .padding(.leading, -12)
                                .background(.white)
                                .pixelBorderSmall()
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                
                // MARK: - 底部创建按钮
                VStack {
                    Spacer()
                    
                    Button(action: createQuest) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                            Text("quest_create".localized)
                                .font(.pixel(20))
                        }
                        .foregroundColor(title.isEmpty ? Color("PixelBorder").opacity(0.5) : Color("PixelBorder"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(title.isEmpty ? Color("PixelAccent").opacity(0.5) : Color("PixelAccent"))
                        .pixelBorderSmall()
                    }
                    .disabled(title.isEmpty)
                    .padding()
                    .background(
                        Color("PixelBg")
                            .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
                    )
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
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            await questStore.addQuest(title: title, xp: xp, type: type, recurrence: recurrence)
            dismiss()
        }
    }
}

// MARK: - 任务类型选择按钮
struct QuestTypeButton: View {
    let type: Quest.QuestType
    let isSelected: Bool
    let onTap: () -> Void
    
    var icon: String {
        switch type {
        case .health: return "heart.fill"
        case .intellect: return "brain.head.profile"
        case .strength: return "dumbbell.fill"
        case .spirit: return "sparkles"
        case .skill: return "wrench.and.screwdriver.fill"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color(type.color))
                
                Text(type.rawValue)
                    .font(.pixel(11))
                    .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(type.color) : Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color(type.color), lineWidth: isSelected ? 0 : 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - XP 选择按钮
struct XPButton: View {
    let value: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(value)")
                .font(.pixel(14))
                .foregroundColor(isSelected ? .white : Color("PixelBorder"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color("PixelAccent") : Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color("PixelAccent"), lineWidth: isSelected ? 0 : 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 周期选择按钮
struct RecurrenceButton: View {
    let recurrence: Quest.QuestRecurrence
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: recurrence.icon)
                    .font(.system(size: 18))
                Text(recurrence.displayName)
                    .font(.pixel(10))
            }
            .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color("PixelBlue") : Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color("PixelBlue"), lineWidth: isSelected ? 0 : 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuestLogSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questStore: QuestStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(questStore.questLog) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.questTitle)
                                        .font(.pixel(18))
                                        .foregroundColor(Color("PixelBorder"))
                                    Text(log.questType.rawValue.uppercased())
                                        .font(.pixel(12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("+\(log.xp) XP")
                                    .font(.pixel(18))
                                    .foregroundColor(Color("PixelAccent"))
                            }
                            .padding()
                            .background(.white)
                            .pixelBorderSmall()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("QUEST LOG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("DONE") { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
    }
}

#Preview {
    QuestsView()
        .environmentObject(QuestStore())
}

import SwiftUI

struct QuestsView: View {
    @EnvironmentObject var questStore: QuestStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showAddSheet = false
    @State private var showLogSheet = false
    
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
                        
                        // Quest List
                        ForEach(questStore.quests.sorted { !$0.completed && $1.completed }) { quest in
                            QuestCardView(quest: quest) {
                                Task {
                                    await questStore.toggleQuest(id: quest.id)
                                }
                            }
                        }
                        .padding(.horizontal)
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
                        .padding(.bottom, 24)
                    }
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
}

struct QuestCardView: View {
    let quest: Quest
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Rectangle()
                        .fill(quest.completed ? Color("PixelGreen") : .white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Rectangle()
                                .stroke(Color("PixelBorder"), lineWidth: 4)
                        )
                    
                    if quest.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
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
                            .background(Color.gray.opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                            )
                        
                        Text("+\(quest.xp) XP")
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelAccent"))
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(quest.completed ? Color("PixelGreen").opacity(0.1) : .white)
            .pixelBorderSmall(color: quest.completed ? Color("PixelGreen") : Color("PixelBorder"))
            .pixelCorners(color: quest.completed ? Color("PixelGreen") : Color("PixelBorder"))
        }
        .buttonStyle(.plain)
        .opacity(quest.completed ? 0.8 : 1)
    }
}

struct AddQuestSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questStore: QuestStore
    @State private var title = ""
    @State private var xp = 50
    @State private var type: Quest.QuestType = .health
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUEST TITLE")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelAccent"))
                        TextField("Enter quest name...", text: $title)
                            .font(.pixel(18))
                            .padding(12)
                            .background(.white)
                            .pixelBorderSmall()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("XP REWARD")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelAccent"))
                        Picker("XP Reward", selection: $xp) {
                            ForEach([25, 50, 75, 100, 150, 200], id: \.self) { value in
                                Text("\(value) XP").tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUEST TYPE")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelAccent"))
                        Picker("Type", selection: $type) {
                            ForEach(Quest.QuestType.allCases, id: \.self) { t in
                                Text(t.rawValue.uppercased()).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await questStore.addQuest(title: title, xp: xp, type: type)
                            dismiss()
                        }
                    }) {
                        Text("CREATE QUEST")
                            .font(.pixel(20))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .navigationTitle("NEW QUEST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
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

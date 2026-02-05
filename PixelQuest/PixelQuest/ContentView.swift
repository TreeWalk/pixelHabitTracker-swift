import SwiftUI

enum HomeHeroID: Hashable {
    case bookkeeping
    case assets
}

struct ContentView: View {
    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            HomeDashboardView(heroNamespace: heroNamespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.creamBg.ignoresSafeArea())
        }
        .transaction { transaction in
            transaction.animation = .easeInOut(duration: 0.4)
        }
    }
}

struct BookkeepingView: View {
    let heroNamespace: Namespace.ID

    private let location = Location(
        id: 4,
        name: "Bookkeeping",
        icon: "company",
        banner: "companyLongMorning",
        type: "Finance",
        desc: "Bookkeeping hub",
        unlocked: true
    )

    var body: some View {
        CompanyDetailView(location: location, showsBackButton: true, heroNamespace: heroNamespace)
    }
}

#Preview {
    struct ContentPreview: View {
        @Namespace private var hero

        var body: some View {
            NavigationStack {
                HomeDashboardView(heroNamespace: hero)
                    .environmentObject(SwiftDataItemStore())
                    .environmentObject(SwiftDataFinanceStore())
                    .environmentObject(LocalizationManager.shared)
            }
        }
    }

    return ContentPreview()
}

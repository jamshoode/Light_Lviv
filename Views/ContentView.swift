import SwiftUI
import Combine

struct ContentView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selection = 0
    @Environment(\.scenePhase) var scenePhase
    @State private var showingAddSchedule = false
    
    var body: some View {
        VStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView(Localization.get("loading"))
                        .tint(.white)
                        .foregroundStyle(.white)
                } else if let errorMessage = viewModel.errorMessage, viewModel.groups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.gray)
                        Button(Localization.get("retry")) {
                            Task {
                                await viewModel.fetchSchedule()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    .padding()
                } else if viewModel.isEmptyState {
                    VStack(spacing: 20) {
                        Text(Localization.get("noGroupsSaved"))
                            .foregroundStyle(.gray)
                            .font(.headline)
                        
                        Button(action: {
                            showingAddSchedule = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                                .padding()
                                .background(Circle().fill(Color(white: 0.1)))
                                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                        }
                    }
                } else {
                    TabView(selection: $selection) {
                        Text("WIP")
                            .font(.largeTitle)
                            .bold()
                            .tabItem {
                                Image("Support icon")
                                Text("Support")
                            }.tag(1)
                        
                        NavigationStack {
                            Home
                        }
                            .tabItem {
                                Image(systemName: "house")
                                Text("Home")
                            }.tag(0)
                        
                        NavigationStack {
                            NotificationsTabView()
                        }
                            .tabItem {
                                Image(systemName: "bell")
                                Text("Notifications")
                            }.tag(2)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GroupRenamed"))) { _ in
                Task {
                    await viewModel.fetchSchedule()
                }
            }
            .sheet(isPresented: $showingAddSchedule) {
                AddScheduleView(vm: viewModel)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            NotificationManager.shared.requestPermission()
            await viewModel.startAutoRefresh()
        }
    }
    
    var Home: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.displayedGroups) { group in
                        NavigationLink(destination: ScheduleDetailView(group: group)) {
                            GroupCardView(group: group)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeGroup(group)
                            } label: {
                                Label(Localization.get("delete"), systemImage: "trash")
                            }
                        }
                    }
                    
                    Button(action: {
                        showingAddSchedule = true
                    }) {
                        VStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color("Plus background"))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "plus")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Text(Localization.get("addGroup"))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 120)
                        .background(AppTheme.cardGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("Card border"), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.fetchSchedule()
            }
        }
        //.navigationTitle(Localization.get("appName"))
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                VStack {
                    HStack(spacing: 6) {
                        Image("App icon")
                            .foregroundStyle(.yellow)
                        Text(Localization.get("appName"))
                            .bold()

                    }
                    .font(.title)
                }
            }
        }
    }
}

struct AppIcon: View {
    var body: some View {
        Rectangle()
            .stroke(Color(red: 1, green: 0.767, blue: 0), lineWidth: 2)
            .frame(width: 14, height: 20)
    }
}

#Preview {
    ContentView()
}

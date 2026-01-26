import SwiftUI

struct AddressSelectionView: View {
    var vm: ScheduleViewModel
    @StateObject private var searchService = ScheduleSearchService()
    
    @Environment(\.dismiss) var dismiss
    
    enum Step {
        case loading
        case settlement
        case street
        case house
        case result(String)
        case error(String)
    }
    
    @State private var currentStep: Step = .loading
    @State private var searchText = ""
    @State private var searchResults: [String] = []
    @State private var debouncer: Task<Void, Never>?
    
    // Selections
    @State private var selectedSettlement: String?
    @State private var selectedStreet: String?
    @State private var selectedHouse: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                switch currentStep {
                case .loading:
                    ProgressView(Localization.get("loading"))
                        .onAppear {
                            loadPage()
                        }
                case .settlement:
                    searchStepView(
                        title: Localization.get("selectSettlement"),
                        placeholder: Localization.get("searchPlaceholder"),
                        stepIndex: 0
                    )
                case .street:
                    searchStepView(
                        title: Localization.get("selectStreet"),
                        placeholder: Localization.get("searchPlaceholder"),
                        stepIndex: 1
                    )
                case .house:
                    searchStepView(
                        title: Localization.get("selectHouse"),
                        placeholder: Localization.get("searchPlaceholder"),
                        stepIndex: 2
                    )
                case .result(let groupId):
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text(Localization.get("groupFound"))
                            .font(.headline)
                        
                        Text(groupId)
                            .font(.system(size: 48, weight: .bold))
                        
                        Button(action: {
                            // Find full group object if possible, or create a stub
                            // We need to fetch the schedule for this group to be useful.
                            // But usually users just want to save the ID.
                            // The `ScheduleViewModel` mostly fetches all and filters by ID.
                            // So adding the ID is enough.
                            
                            // We need to construct a ScheduleGroup object.
                            // We don't have the schedule yet, but `fetchSchedule` will get it.
                            let newGroup = ScheduleGroup(id: groupId, subGroupName: groupId, schedules: [:], lastUpdateTimestamp: nil)
                            vm.addGroup(newGroup)
                            vm.isLoading = true // Trigger refresh
                            Task {
                                await vm.fetchSchedule()
                            }
                            dismiss()
                        }) {
                            Text(Localization.get("addGroup"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundStyle(.black)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                case .error(let msg):
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(msg)
                            .padding()
                        Button(Localization.get("retry")) {
                            loadPage()
                        }
                    }
                }
            }
            .navigationTitle(Localization.get("findByAddress"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.get("cancel")) {
                        dismiss()
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    func searchStepView(title: String, placeholder: String, stepIndex: Int) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding()
            
            // Current selections summary
            if let s = selectedSettlement {
                HStack {
                    Text(s)
                    Spacer()
                    Image(systemName: "checkmark")
                }
                .padding()
                .background(Color(white: 0.1))
                .foregroundStyle(.gray)
            }
            if let st = selectedStreet {
                HStack {
                    Text(st)
                    Spacer()
                    Image(systemName: "checkmark")
                }
                .padding()
                .background(Color(white: 0.1))
                .foregroundStyle(.gray)
            }
            
            TextField(placeholder, text: $searchText)
                .padding(12)
                .background(Color(white: 0.15))
                .cornerRadius(8)
                .padding()
                .onChange(of: searchText) { oldValue, newValue in
                    performSearch(query: newValue, stepIndex: stepIndex)
                }
                .onAppear {
                    // Trigger initial search to get default options
                    performSearch(query: searchText, stepIndex: stepIndex)
                }
            
            List(searchResults, id: \.self) { result in
                Button(action: {
                    selectResult(result, stepIndex: stepIndex)
                }) {
                    Text(result)
                        .foregroundStyle(.white)
                }
            }
            .listStyle(.plain)
             
            if searchService.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }
    
    private func loadPage() {
        currentStep = .loading
        Task {
            do {
                try await searchService.loadPage()
                // Auto-focus settlement search or just ready state
                // Actually to get initial list of settlements we might need to search empty or just "м. Львів" defaults?
                // The site usually requires typing.
                currentStep = .settlement
            } catch {
                currentStep = .error(error.localizedDescription)
            }
        }
    }
    
    private func performSearch(query: String, stepIndex: Int) {
        debouncer?.cancel()
        debouncer = Task {
            try? await Task.sleep(nanoseconds: 500 * 1_000_000) // 0.5s debounce
            if Task.isCancelled { return }
            
            // Allow empty query to fetch defaults
            // if query.isEmpty { ... } check removed
            
            do {
                let results = try await searchService.search(query: query, stepIndex: stepIndex)
                await MainActor.run {
                    self.searchResults = results
                }
            } catch {
                print("Search error: \(error)")
            }
        }
    }
    
    private func selectResult(_ result: String, stepIndex: Int) {
        Task {
            do {
                try await searchService.selectOption(name: result)
                
                await MainActor.run {
                    self.searchText = ""
                    self.searchResults = []
                    
                    switch stepIndex {
                    case 0:
                        selectedSettlement = result
                        currentStep = .street
                    case 1:
                        selectedStreet = result
                        currentStep = .house
                    case 2:
                        selectedHouse = result
                        // After selecting house, we fetch group
                        finishSelection()
                    default:
                        break
                    }
                }
            } catch {
                currentStep = .error("Failed to select option: \(error.localizedDescription)")
            }
        }
    }
    
    private func finishSelection() {
        Task {
            do {
                let group = try await searchService.getScheduleGroup()
                await MainActor.run {
                    self.currentStep = .result(group)
                }
            } catch {
                await MainActor.run {
                    self.currentStep = .error("Failed to get group: \(error.localizedDescription)")
                }
            }
        }
    }
}

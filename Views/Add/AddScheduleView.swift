import SwiftUI

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    
    var vm: ScheduleViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if vm.isLoading && vm.groups.isEmpty {
                    ProgressView(Localization.get("loading"))
                        .tint(.white)
                        .foregroundStyle(.white)
                } else {
                    List {
                        Section {
                            NavigationLink(destination: AddressSelectionView(vm: vm)) {
                                Label(Localization.get("findByAddress"), systemImage: "magnifyingglass")
                                    .foregroundStyle(.white)
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        
                        Section(header: Text(Localization.get("selectGroup"))) {
                            ForEach(vm.groups) { group in
                                HStack {
                                    Text("\(Localization.get("group")) \(group.subGroupName)")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if vm.isGroupAdded(group) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .contentShape(Rectangle())
                                .listRowBackground(Color(white: 0.1))
                                .onTapGesture {
                                    if vm.isGroupAdded(group) {
                                        vm.removeGroup(group)
                                    } else {
                                        vm.addGroup(group)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(Localization.get("addSchedule"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Localization.get("done")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

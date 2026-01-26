import SwiftUI

struct RenameGroupView: View {
    let group: ScheduleGroup
    @State private var newName: String = ""
    @Environment(\.dismiss) var dismiss
    var onRename: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Localization.get("enterName"), text: $newName)
                } header: {
                    Text(Localization.get("enterName"))
                } footer: {
                    Text("Example: \"Home\", \"Office\"")
                }
            }
            .navigationTitle(Localization.get("renameGroup"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.get("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.get("save")) {
                        NotificationManager.shared.setNickname(newName, for: group)
                        onRename()
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                newName = group.customName ?? ""
            }
        }
    }
}

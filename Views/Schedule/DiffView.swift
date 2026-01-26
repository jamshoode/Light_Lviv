import SwiftUI

struct DiffView: View {
    let oldSchedule: String
    let newSchedule: String
    let timestamp: String? // "Information as of..."
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let ts = timestamp {
                        Text(ts)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Previous Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Localization.get("previous"))
                                .font(.headline)
                                .foregroundStyle(.gray)
                            
                            VisualScheduleView(text: oldSchedule)
                                .opacity(0.7) // Dim old one slightly
                        }
                        
                        Divider()
                            .background(Color(white: 0.3))
                        
                        // Current Column
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Localization.get("current"))
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            VisualScheduleView(text: newSchedule)
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(Localization.get("viewChanges"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

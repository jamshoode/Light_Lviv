import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .black : .white)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // Better tap area
        }
        .buttonStyle(.plain)
    }
}

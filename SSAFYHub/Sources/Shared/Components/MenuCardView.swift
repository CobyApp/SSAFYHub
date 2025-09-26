import SwiftUI

struct MenuCardView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(AppTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    if !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(color.opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(item)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    MenuCardView(
        title: "A타입",
        items: ["김치찌개", "제육볶음", "시금치나물"],
        color: AppColors.accentPrimary
    )
}

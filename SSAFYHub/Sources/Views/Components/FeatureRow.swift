import SwiftUI

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        FeatureRow(
            icon: "camera.fill",
            title: "사진으로 메뉴 인식",
            description: "OCR 기술로 식단표를 자동으로 읽어옵니다"
        )
        
        FeatureRow(
            icon: "calendar",
            title: "날짜별 메뉴 확인",
            description: "월~금까지 각 날짜의 메뉴를 쉽게 확인하세요"
        )
        
        FeatureRow(
            icon: "building.2.fill",
            title: "캠퍼스별 메뉴",
            description: "서울, 대전, 광주, 구미, 부산 캠퍼스 메뉴"
        )
    }
    .padding()
}

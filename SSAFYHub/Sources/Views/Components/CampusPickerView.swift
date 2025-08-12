import SwiftUI

// MARK: - Campus Picker View
struct CampusPickerView: View {
    @Binding var selectedCampus: Campus
    let onCampusSelected: (Campus) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 제목
            VStack(spacing: 8) {
                Text("캠퍼스 선택")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("현재는 대전캠퍼스만 지원됩니다")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // 캠퍼스 목록
            VStack(spacing: 16) {
                ForEach(Campus.allCases, id: \.self) { campus in
                    CampusRowView(
                        campus: campus,
                        isSelected: selectedCampus == campus,
                        isAvailable: campus.isAvailable
                    ) {
                        // 대전캠퍼스만 선택 가능
                        if campus == .daejeon {
                            selectedCampus = campus
                            onCampusSelected(campus)
                        }
                        // 다른 캠퍼스는 선택 불가 (아무 동작 안함)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 계속하기 버튼
            Button(action: {
                onCampusSelected(selectedCampus)
            }) {
                Text("계속하기")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedCampus.isAvailable ? AppColors.primary : AppColors.disabled)
                    .cornerRadius(16)
            }
            .disabled(!selectedCampus.isAvailable)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundPrimary)
        .onAppear {
            // 기본값을 대전으로 설정
            if !selectedCampus.isAvailable {
                selectedCampus = .daejeon
            }
        }
    }
}

// MARK: - Campus Row View
struct CampusRowView: View {
    let campus: Campus
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 선택 상태 표시
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primary : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .stroke(AppColors.border, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
                
                // 캠퍼스 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(campus.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(isAvailable ? AppColors.textPrimary : AppColors.textSecondary)
                        
                        Spacer()
                        
                        // 상태 표시
                        Text(isAvailable ? "활성" : "준비중")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(isAvailable ? AppColors.success : AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isAvailable ? AppColors.success.opacity(0.1) : AppColors.disabled.opacity(0.1))
                            )
                    }
                    
                    Text(isAvailable ? "현재 지원되는 캠퍼스" : "준비중 (추후 확정 예정)")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(isAvailable ? AppColors.textSecondary : AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAvailable ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(!isAvailable) // 대전이 아닌 캠퍼스는 완전히 비활성화
        .opacity(isAvailable ? 1.0 : 0.6) // 비활성화된 캠퍼스는 투명도 낮춤
    }
}

#Preview {
    CampusPickerView(
        selectedCampus: .constant(.daejeon),
        onCampusSelected: { _ in }
    )
}

import SwiftUI

struct CampusSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var selectedCampus: Campus = .seoul
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "building.2")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("캠퍼스를 선택해주세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("선택한 캠퍼스의 점심 메뉴를 확인할 수 있습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            
            // Campus Options
            VStack(spacing: 16) {
                ForEach(Campus.allCases, id: \.self) { campus in
                    CampusOptionRow(
                        campus: campus,
                        isSelected: selectedCampus == campus
                    ) {
                        selectedCampus = campus
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                print("🚀 계속하기 버튼 클릭됨")
                print("📍 선택된 캠퍼스: \(selectedCampus.displayName)")
                
                // 게스트 사용자로 메인 화면으로 이동
                Task {
                    print("🎯 게스트 모드 캠퍼스 선택 완료")
                    await authViewModel.signInAsGuest(campus: selectedCampus)
                    
                    // 캠퍼스 선택 완료 후 Coordinator에 알림
                    await MainActor.run {
                        appCoordinator.completeCampusSelection(selectedCampus)
                    }
                }
            }) {
                Text("계속하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("캠퍼스 선택")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("뒤로") {
                    appCoordinator.navigateToAuth()
                }
            }
        }
    }
}

// MARK: - Campus Option Row
struct CampusOptionRow: View {
    let campus: Campus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campus.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(campus.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CampusSelectionView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
}

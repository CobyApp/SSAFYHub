import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 프로필 섹션
                    profileSection
                    
                    // 테마 설정 섹션
                    themeSection
                    
                    // 계정 관리 섹션
                    accountSection
                    
                    // 앱 정보 섹션
                    appInfoSection
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                print("🔍 SettingsView onAppear")
                print("🔍 currentUser: \(String(describing: authViewModel.currentUser))")
                print("🔍 authState: \(authViewModel.authState)")
                if let user = authViewModel.currentUser {
                    print("🔍 userType: \(user.userType)")
                    print("🔍 isGuest: \(user.isGuest)")
                }
            }
        }
        .environmentObject(themeManager)
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(authViewModel.currentUser?.email ?? "사용자")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("가입일: \(authViewModel.currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "날짜 없음")")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    HStack {
                        Image(systemName: authViewModel.currentUser?.isGuest == true ? "person.badge.plus" : "checkmark.seal.fill")
                            .foregroundColor(authViewModel.currentUser?.isGuest == true ? AppColors.warning : AppColors.success)
                        
                        Text(authViewModel.currentUser?.isGuest == true ? "게스트 사용자" : "인증된 사용자")
                            .font(AppTypography.caption1)
                            .foregroundColor(authViewModel.currentUser?.isGuest == true ? AppColors.warning : AppColors.success)
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("테마 설정")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                
                Text("다크 모드")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $themeManager.isDarkMode)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppCornerRadius.medium)
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("계정 관리")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                Button(action: {
                    // 캠퍼스 변경 로직
                }) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        Text("캠퍼스 변경")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                Button(action: {
                    if let currentUser = authViewModel.currentUser, currentUser.isGuest {
                        // 게스트 모드 나가기
                        authViewModel.exitGuestMode()
                        dismiss()
                    } else {
                        // 인증된 사용자 로그아웃
                        Task {
                            await authViewModel.signOut()
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: authViewModel.currentUser?.isGuest == true ? "xmark.circle" : "rectangle.portrait.and.arrow.right")
                            .foregroundColor(authViewModel.currentUser?.isGuest == true ? AppColors.textSecondary : AppColors.error)
                            .frame(width: 24)
                        
                        Text(authViewModel.currentUser?.isGuest == true ? "나가기" : "로그아웃")
                            .font(AppTypography.body)
                            .foregroundColor(authViewModel.currentUser?.isGuest == true ? AppColors.textSecondary : AppColors.error)
                        
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("앱 정보")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text("버전")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppCornerRadius.medium)
                
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text("개발자")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("SSAFY")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppCornerRadius.medium)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}


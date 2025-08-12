import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 테마 설정 섹션
                    themeSection
                    
                    // 캠퍼스 설정 섹션
                    campusSection
                    
                    // 게스트 모드일 때: 나가기 버튼
                    if let currentUser = authViewModel.currentUser, currentUser.isGuest {
                        guestExitSection
                    }
                    
                    // 계정 관리 섹션 (인증된 사용자만 표시)
                    if let currentUser = authViewModel.currentUser, !currentUser.isGuest {
                        accountSection
                    }
                    
                    // 앱 정보 섹션
                    appInfoSection
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .environmentObject(themeManager)
        .alert("로그아웃", isPresented: $showingLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("회원탈퇴", isPresented: $showingDeleteAccountAlert) {
            Button("취소", role: .cancel) { }
            Button("회원탈퇴", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("정말 회원탈퇴 하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("테마 설정")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text("다크 모드")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $themeManager.isDarkMode)
                        .onChange(of: themeManager.isDarkMode) { newValue in
                            themeManager.setTheme(newValue)
                        }
                }
                .padding(AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppCornerRadius.medium)
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24)
                    
                    Text("시스템 설정과 동기화")
                        .font(AppTypography.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }
    
    // MARK: - Campus Section
    private var campusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("캠퍼스 설정")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                // 현재 선택된 캠퍼스 표시
                if let currentUser = authViewModel.currentUser {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("현재 캠퍼스")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(currentUser.campus.displayName)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Spacer()
                        
                        Text("선택됨")
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppCornerRadius.small)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.primary.opacity(0.05))
                    .cornerRadius(AppCornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 캠퍼스 선택 옵션
                VStack(spacing: AppSpacing.sm) {
                    Text("캠퍼스 변경")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, AppSpacing.sm)
                    
                    ForEach(Campus.allCases, id: \.self) { campus in
                        Button(action: {
                            if campus.isAvailable {
                                Task {
                                    await changeUserCampus(to: campus)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: campus.isAvailable ? "building.2.fill" : "clock.circle.fill")
                                    .foregroundColor(campus.isAvailable ? AppColors.primary : AppColors.disabled)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(campus.displayName)
                                        .font(AppTypography.body)
                                        .foregroundColor(campus.isAvailable ? AppColors.textPrimary : AppColors.textSecondary)
                                    
                                    Text(campus.isAvailable ? "클릭하여 선택" : "준비중 (추후 확정 예정)")
                                        .font(AppTypography.caption1)
                                        .foregroundColor(campus.isAvailable ? AppColors.textSecondary : AppColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if campus.isAvailable {
                                    if let currentUser = authViewModel.currentUser, currentUser.campus == campus {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.success)
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.primary)
                                            .font(.system(size: 16))
                                    }
                                } else {
                                    Text("준비중")
                                        .font(AppTypography.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(AppColors.disabled.opacity(0.1))
                                        .cornerRadius(AppCornerRadius.small)
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .fill(campus.isAvailable ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(
                                        campus.isAvailable ? AppColors.border : AppColors.disabled.opacity(0.3), 
                                        lineWidth: 1
                                    )
                            )
                        }
                        .disabled(!campus.isAvailable)
                    }
                }
            }
        }
    }
    
    // MARK: - 캠퍼스 변경 함수
    private func changeUserCampus(to newCampus: Campus) async {
        guard let currentUser = authViewModel.currentUser else { return }
        
        print("🏫 캠퍼스 변경 시작: \(currentUser.campus.displayName) → \(newCampus.displayName)")
        
        do {
            // SupabaseService를 통해 캠퍼스 업데이트
            try await authViewModel.supabaseService.updateUserCampus(
                userId: currentUser.id, 
                campus: newCampus
            )
            
            print("✅ 캠퍼스 변경 성공")
            
            // 성공 메시지 표시 (필요시)
            // TODO: 성공 알림 추가
            
        } catch {
            print("❌ 캠퍼스 변경 실패: \(error)")
            // TODO: 에러 알림 추가
        }
    }
    
    // MARK: - 회원탈퇴 함수
    private func deleteAccount() async {
        guard let currentUser = authViewModel.currentUser else { return }
        
        print("🗑️ 회원탈퇴 시작: \(currentUser.email)")
        
        do {
            // AuthViewModel을 통해 회원탈퇴
            await authViewModel.deleteAccount()
            dismiss()
            print("✅ 회원탈퇴 완료")
        } catch {
            print("❌ 회원탈퇴 실패: \(error)")
            // TODO: 에러 알림 추가
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("계정 관리")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                // 로그아웃 버튼
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppColors.error)
                            .frame(width: 24)
                        
                        Text("로그아웃")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.error)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                // 회원탈퇴 버튼
                Button(action: {
                    showingDeleteAccountAlert = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .foregroundColor(AppColors.error)
                            .frame(width: 24)
                        
                        Text("회원탈퇴")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.error)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }
    
    // MARK: - Guest Exit Section
    private var guestExitSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("게스트 모드")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                Button(action: {
                    // 게스트 모드 종료 후 회원가입 화면으로 이동
                    Task {
                        await authViewModel.signOut()
                        dismiss()
                        // AppCoordinator를 통해 회원가입 화면으로 이동
                        await MainActor.run {
                            appCoordinator.navigateToAuth()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        
                        Text("게스트 모드 나가기")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
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
                    Image(systemName: "envelope.fill")
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24)
                    
                    Text("개발자")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("coby5502@gmail.com")
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
        .environmentObject(AppCoordinator())
}


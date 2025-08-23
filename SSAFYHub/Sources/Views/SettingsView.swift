import SwiftUI
import ComposableArchitecture
import SharedModels

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                // 커스텀 헤더
                customHeader
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 캠퍼스 설정 섹션
                        campusSection(viewStore)
                        
                        // 테마 설정 섹션
                        themeSection
                        
                        // 계정 관리 섹션 (인증된 사용자만 표시)
                        if let currentUser = viewStore.currentUser, !currentUser.isGuest {
                            accountSection(viewStore)
                        }
                        
                        // 게스트 모드 섹션 (게스트 사용자만 표시)
                        if let currentUser = viewStore.currentUser, currentUser.isGuest {
                            guestSection(viewStore)
                        }
                        
                        // 앱 정보 섹션
                        appInfoSection
                    }
                    .padding(AppSpacing.lg)
                }
                .background(AppColors.backgroundPrimary)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .alert("로그아웃", isPresented: .constant(viewStore.showingSignOutAlert)) {
                Button("취소", role: .cancel) {
                    viewStore.send(.cancelSignOut)
                }
                Button("로그아웃", role: .destructive) {
                    viewStore.send(.confirmSignOut)
                }
            } message: {
                Text("정말 로그아웃 하시겠습니까?")
            }
            .alert("오류", isPresented: .constant(viewStore.errorMessage != nil)) {
                Button("확인") {
                    viewStore.send(.clearError)
                }
            } message: {
                if let errorMessage = viewStore.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        VStack(spacing: 0) {
            // 상단 뒤로가기 버튼
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(AppColors.backgroundTertiary)
                        .cornerRadius(22)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("테마 설정")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { themeMode in
                    Button(action: {
                        themeManager.setThemeMode(themeMode)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(themeMode.displayName)
                                    .font(AppTypography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("\(themeMode.displayName) 테마로 설정")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if themeManager.themeMode == themeMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accentPrimary)
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if themeMode != ThemeManager.ThemeMode.allCases.last {
                        Divider()
                    }
                }
            }
            .background(AppColors.surfaceSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Campus Section
    @ViewBuilder
    private func campusSection(_ viewStore: ViewStoreOf<SettingsFeature>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("캠퍼스 설정")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(Campus.allCases, id: \.self) { campus in
                    campusRow(campus: campus, viewStore: viewStore)
                }
            }
        }
    }
    
    // MARK: - Campus Row
    @ViewBuilder
    private func campusRow(campus: Campus, viewStore: ViewStoreOf<SettingsFeature>) -> some View {
        Button(action: {
            if campus.isAvailable {
                // TODO: 캠퍼스 변경 로직 구현
                print("🏫 캠퍼스 변경: \(campus.displayName)")
            }
        }) {
            HStack {
                campusIcon(campus: campus)
                campusInfo(campus: campus)
                Spacer()
                campusStatus(campus: campus, viewStore: viewStore)
            }
            .padding(AppSpacing.md)
            .background(campusBackground(campus: campus))
            .overlay(campusBorder(campus: campus))
        }
        .disabled(!campus.isAvailable)
    }
    
    // MARK: - Campus Icon
    @ViewBuilder
    private func campusIcon(campus: Campus) -> some View {
        Image(systemName: campus.isAvailable ? "building.2.fill" : "clock.circle.fill")
            .foregroundColor(campus.isAvailable ? AppColors.primary : AppColors.disabled)
            .frame(width: 24)
    }
    
    // MARK: - Campus Info
    @ViewBuilder
    private func campusInfo(campus: Campus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(campus.displayName)
                .font(AppTypography.body)
                .foregroundColor(campus.isAvailable ? AppColors.textPrimary : AppColors.textSecondary)
            
            Text(campus.isAvailable ? "클릭하여 선택" : "준비중 (추후 확장 예정)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Campus Status
    @ViewBuilder
    private func campusStatus(campus: Campus, viewStore: ViewStoreOf<SettingsFeature>) -> some View {
        if campus.isAvailable {
            if let currentUser = viewStore.currentUser, currentUser.campus == campus {
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
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppColors.disabled.opacity(0.1))
                .cornerRadius(AppCornerRadius.small)
        }
    }
    
    // MARK: - Campus Background
    @ViewBuilder
    private func campusBackground(campus: Campus) -> some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
            .fill(campus.isAvailable ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.opacity(0.5))
    }
    
    // MARK: - Campus Border
    @ViewBuilder
    private func campusBorder(campus: Campus) -> some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
            .stroke(
                campus.isAvailable ? AppColors.border : AppColors.disabled.opacity(0.3), 
                lineWidth: 1
            )
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func accountSection(_ viewStore: ViewStoreOf<SettingsFeature>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("계정 관리")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                // 사용자 정보
                if let currentUser = viewStore.currentUser {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("로그인 정보")
                                .font(AppTypography.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(currentUser.email)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.accentPrimary)
                    }
                    .padding(AppSpacing.md)
                    
                    Divider()
                }
                
                // 로그아웃 버튼
                Button(action: {
                    viewStore.send(.signOutTapped)
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppColors.error)
                            .frame(width: 24)
                        
                        Text("로그아웃")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.error)
                        
                        Spacer()
                        
                        if viewStore.isSigningOut {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textTertiary)
                                .font(.caption)
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .disabled(viewStore.isSigningOut)
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.surfaceSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Guest Section
    @ViewBuilder
    private func guestSection(_ viewStore: ViewStoreOf<SettingsFeature>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("게스트 모드")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                Button(action: {
                    // 게스트 모드 종료
                    viewStore.send(.exitGuestMode)
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundColor(AppColors.error)
                            .frame(width: 24)
                        
                        Text("게스트 모드 나가기")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.error)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textTertiary)
                            .font(.caption)
                    }
                    .padding(AppSpacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppColors.surfaceSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("앱 정보")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
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
                    
                    Text("1.0.5")
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
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
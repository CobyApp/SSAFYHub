import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject var menuViewModel = MenuViewModel()
    @State private var showMenuEditor = false
    @State private var showSettings = false
    @State private var showGuestAccessAlert = false
    
    // 한글 요일 텍스트
    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: menuViewModel.currentDate)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    headerView
                    
                    // 메뉴 컨텐츠
                    if let menu = menuViewModel.currentMenu {
                        menuContentView(menu)
                    } else {
                        emptyMenuView
                    }
                    
                    Spacer(minLength: 20)
                }
                .background(Color(.systemBackground))
            }
            .refreshable {
                // 당기면 새로고침
                print("🔄 메뉴 새로고침 시작")
                await refreshMenu()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if let currentUser = authViewModel.currentUser {
                // 사용자의 캠퍼스 정보가 있으면 사용, 없으면 대전으로 설정
                let userCampus = currentUser.campus
                if userCampus.isAvailable {
                    menuViewModel.selectedCampus = userCampus
                } else {
                    menuViewModel.selectedCampus = .daejeon
                }
                menuViewModel.loadMenuForCurrentDate()
            } else {
                // 게스트 사용자일 경우 대전으로 설정
                menuViewModel.selectedCampus = .daejeon
                menuViewModel.loadMenuForCurrentDate()
            }
        }
        .fullScreenCover(isPresented: $showMenuEditor) {
            if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                MenuEditorView(
                    menuViewModel: menuViewModel,
                    date: menuViewModel.currentDate
                )
                .environmentObject(authViewModel)
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authViewModel)
                .environmentObject(appCoordinator)
        }
        .alert("게스트 모드 제한", isPresented: $showGuestAccessAlert) {
            Button("확인") { }
        } message: {
            Text("게스트 사용자는 메뉴 편집이 제한됩니다. Apple ID로 로그인하여 모든 기능을 이용하세요.")
        }
    }
    
    // MARK: - 새로고침 함수
    private func refreshMenu() async {
        print("🔄 메뉴 새로고침 실행")
        
        // 현재 날짜의 메뉴 다시 로드
        await MainActor.run {
            menuViewModel.loadMenuForCurrentDate()
        }
        
        // 잠시 대기 (로고침 애니메이션을 위해)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        print("✅ 메뉴 새로고침 완료")
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // 상단 설정 버튼
            HStack {
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // 메인 헤더
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("오늘의 메뉴")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let currentUser = authViewModel.currentUser {
                            Text(currentUser.campus.displayName)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            // 게스트 사용자일 경우 대전캠퍼스 표시
                            Text("대전캠퍼스")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 날짜 표시
                HStack {
                    Text(menuViewModel.currentDate, style: .date)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(weekdayText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                }
                
                // 게스트 모드 배너
                if let currentUser = authViewModel.currentUser, currentUser.isGuest {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.warning)
                        
                        Text("게스트 모드 - 제한된 기능")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.warning)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.warning.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Menu Content View
    private func menuContentView(_ menu: Menu) -> some View {
        VStack(spacing: 20) {
            // A타입 메뉴
            if !menu.itemsA.isEmpty {
                menuSection(title: "A타입", items: menu.itemsA, color: AppColors.primary)
            }
            
            // B타입 메뉴
            if !menu.itemsB.isEmpty {
                menuSection(title: "B타입", items: menu.itemsB, color: AppColors.success)
            }
            
            // 메뉴 수정 버튼 (인증된 사용자만)
            if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                Button(action: { showMenuEditor = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.primary)
                        
                        Text("메뉴 수정하기")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(20)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Menu Section
    private func menuSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(items.count)개")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Empty Menu View
    private var emptyMenuView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 8) {
                    Text("오늘 등록된 메뉴가 없습니다")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                        Text("아래 버튼을 눌러 메뉴를 등록해보세요")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("Apple ID로 로그인하여 메뉴를 등록할 수 있습니다")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            // 메뉴 추가 버튼 (인증된 사용자만)
            if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                Button(action: { showMenuEditor = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("이번주 메뉴 추가하기")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(AppColors.primary)
                    .cornerRadius(16)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MainMenuView()
        .environmentObject(AuthViewModel())
}


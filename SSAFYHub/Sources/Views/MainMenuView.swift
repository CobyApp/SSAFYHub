import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
            VStack(spacing: 0) {
                // 헤더
                headerView
                
                // 메뉴 컨텐츠
                if let menu = menuViewModel.currentMenu {
                    menuContentView(menu)
                } else {
                    emptyMenuView
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            if let currentUser = authViewModel.currentUser {
                menuViewModel.selectedCampus = currentUser.campus
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
        }
        .alert("게스트 모드 제한", isPresented: $showGuestAccessAlert) {
            Button("확인") { }
        } message: {
            Text("게스트 사용자는 메뉴 편집이 제한됩니다. Apple ID로 로그인하여 모든 기능을 이용하세요.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
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
                        }
                    }
                    
                    Spacer()
                    
                    // 우측 상단 버튼들
                    HStack(spacing: 16) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(22)
                        }
                        
                        if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                            Button(action: { showMenuEditor = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(AppColors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(22)
                            }
                        } else {
                            Button(action: { showGuestAccessAlert = true }) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(AppColors.warning)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(22)
                            }
                        }
                    }
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
            .padding(.top, 16)
            .padding(.bottom, 24)
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
                        Text("+ 버튼을 눌러 메뉴를 등록해보세요")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
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


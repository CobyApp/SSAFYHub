import SwiftUI
import SharedModels

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject var menuViewModel = MenuViewModel()
    @State private var showMenuEditor = false

    @State private var showGuestAccessAlert = false
    
    // 한글 요일 텍스트
    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: menuViewModel.currentDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            headerView
            
            ScrollView {
                VStack(spacing: 0) {
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

            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let translation = value.translation
                        if translation.width > threshold {
                            // 오른쪽으로 스와이프 - 이전 날짜
                            print("👈 오른쪽 스와이프 - 이전 날짜로 이동")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                menuViewModel.goToPreviousDay()
                            }
                        } else if translation.width < -threshold {
                            // 왼쪽으로 스와이프 - 다음 날짜
                            print("👉 왼쪽 스와이프 - 다음 날짜로 이동")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                menuViewModel.goToNextDay()
                            }
                        }
                    }
            )
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

        .alert("게스트 모드 제한", isPresented: $showGuestAccessAlert) {
            Button("확인") { }
        } message: {
            Text("게스트 사용자는 메뉴 편집이 제한됩니다. Apple ID로 로그인하여 모든 기능을 이용하세요.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // 상단 설정 버튼과 메인 헤더를 한 줄에 배치
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("식단표")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let currentUser = authViewModel.currentUser {
                        Text(currentUser.campus.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("대전캠퍼스")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    appCoordinator.navigateToSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            
            // 날짜 표시 (화살표 터치 가능, 날짜와 요일 한 줄)
            HStack {
                Button(action: {
                    print("👈 왼쪽 화살표 터치 - 이전 날짜로 이동")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        menuViewModel.goToPreviousDay()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(16)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(menuViewModel.currentDate, style: .date)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("•")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(weekdayText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    print("👉 오른쪽 화살표 터치 - 다음 날짜로 이동")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        menuViewModel.goToNextDay()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Menu Content View
    private func menuContentView(_ menu: MealMenu) -> some View {
        VStack(spacing: 20) {
            // A타입과 B타입이 모두 비어있는지 확인 (빈 문자열도 체크)
            let hasMenuA = !menu.itemsA.isEmpty && !menu.itemsA.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let hasMenuB = !menu.itemsB.isEmpty && !menu.itemsB.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if hasMenuA || hasMenuB {
                // A타입 메뉴
                if hasMenuA {
                    menuSection(title: "A타입", items: menu.itemsA, color: AppColors.primary)
                }
                
                // B타입 메뉴
                if hasMenuB {
                    menuSection(title: "B타입", items: menu.itemsB, color: AppColors.success)
                }
            } else {
                // A타입과 B타입이 모두 비어있으면 메뉴 없음 표시
                emptyMenuView
            }
            
            // 메뉴 수정 버튼 (인증된 사용자) 또는 게스트나가기 버튼 (게스트 사용자)
            if let currentUser = authViewModel.currentUser {
                if currentUser.isAuthenticated {
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
                } else if currentUser.isGuest {
                    Button(action: {
                        Task {
                            await authViewModel.exitGuestMode()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.error)
                            
                            Text("게스트 모드 나가기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.error)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.error)
                        }
                        .padding(20)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                        )
                    }
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
    
    // MARK: - Holiday View
    private var holidayView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 8) {
                    Text("공휴일")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("오늘은 공휴일입니다")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
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
            

            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    MainMenuView()
        .environmentObject(AuthViewModel())
}


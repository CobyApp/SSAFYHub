import SwiftUI

@main
struct SSAFYHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appCoordinator.currentRoute {
                case .loading:
                    LoadingView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                        .environmentObject(themeManager)
                case .auth:
                    AuthView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                        .environmentObject(themeManager)
                        .onAppear {
                            // Coordinator 연결
                            authViewModel.setCoordinator(appCoordinator)
                        }
                case .mainMenu:
                    MainMenuView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                        .environmentObject(themeManager)
                case .settings:
                    SettingsView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                        .environmentObject(themeManager)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appCoordinator.currentRoute)
            .onChange(of: authViewModel.authState) { oldValue, newValue in
                print("🔄 SSAFYHubApp에서 authState 변경 감지")
                print("📱 이전 상태: \(oldValue)")
                print("📱 새로운 상태: \(newValue)")
                
                // 인증된 상태인지 확인하고 Coordinator에 알림
                if case .authenticated(let user) = newValue {
                    print("✅ 인증된 사용자: \(user.email) - \(user.campus.displayName)")
                    
                    // 게스트 모드 사용자는 앱 재시작 시 로그인 화면으로 가야 함
                    // 세션이 저장되지 않으므로 앱 재시작 시 unauthenticated 상태가 됨
                    if user.userType == .guest {
                        print("👤 게스트 모드 사용자 - 앱 재시작 시 로그인 화면으로 이동")
                        return
                    }
                    
                    // 이미 메인화면에 있다면 중복 네비게이션 방지
                    if appCoordinator.currentRoute != .mainMenu {
                        print("🎯 Coordinator에 사용자 인증 처리 요청")
                        appCoordinator.handleUserAuthentication(user)
                    } else {
                        print("⚠️ 이미 메인화면에 있음, 중복 네비게이션 방지")
                    }
                } else if case .unauthenticated = newValue {
                    print("🚪 로그아웃됨, 인증 화면으로 이동")
                    appCoordinator.resetToAuth()
                }
            }
            .onAppear {
                // 앱 시작 시 로그인 상태 확인
                print("🚀 앱 시작 - 로그인 상태 확인")
                
                // 2초간 로딩 화면 표시 후 상태 확인
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    checkInitialAuthState()
                }
            }
            .onChange(of: colorScheme) { oldValue, newValue in
                // 시스템 테마 변경 감지
                themeManager.systemThemeChanged()
            }
        }
    }
    
    // MARK: - Initial Auth State Check
    private func checkInitialAuthState() {
        Task {
            do {
                print("🔍 SSAFYHubApp: 세션 상태 확인 시작")
                
                // 1. 먼저 저장된 사용자 세션에서 복구 시도
                if let savedUser = await authViewModel.supabaseService.restoreUserSession() {
                    // 게스트 모드 사용자는 복구하지 않음
                    if savedUser.userType == .guest {
                        print("👤 게스트 모드 사용자 세션 발견 - 복구하지 않음")
                        print("🔍 SSAFYHubApp: 게스트 모드는 임시 사용자이므로 세션 복구하지 않음")
                    } else {
                        print("🔍 SSAFYHubApp: 저장된 사용자 세션 발견 - \(savedUser.email)")
                        
                        await MainActor.run {
                            print("✅ 앱 시작 시 저장된 사용자 세션으로 로그인 복구: \(savedUser.email)")
                            authViewModel.authState = .authenticated(savedUser)
                            
                            print("🏫 기존 캠퍼스 정보: \(savedUser.campus.displayName)")
                            appCoordinator.navigateToMainMenuWithCampus(savedUser.campus)
                        }
                        return
                    }
                }
                
                // 2. Supabase 자동 세션 확인
                do {
                    let session = try await authViewModel.supabaseService.getCurrentSession()
                    let user = session.user
                    print("🔍 SSAFYHubApp: Supabase 세션 발견 - 사용자 ID: \(user.id)")
                    
                    // 사용자 데이터 로드
                    let userData = try await authViewModel.fetchUserData(userId: user.id.uuidString)
                    print("🔍 SSAFYHubApp: 사용자 데이터 로드 완료 - \(userData.email)")
                    
                    // 사용자 세션 저장 (Apple 로그인 사용자도 포함)
                    await authViewModel.supabaseService.saveUserSession(userData)
                    print("🔍 SSAFYHubApp: 사용자 세션 저장 완료 - \(userData.email)")
                    
                    await MainActor.run {
                        print("✅ 앱 시작 시 Supabase 세션으로 로그인 발견: \(userData.email)")
                        authViewModel.authState = .authenticated(userData)
                        
                        print("🏫 기존 캠퍼스 정보: \(userData.campus.displayName)")
                        appCoordinator.navigateToMainMenuWithCampus(userData.campus)
                    }
                } catch {
                    print("🔍 SSAFYHubApp: Supabase 세션 없음, 수동 세션 복구 시도")
                    
                    // 3. 수동 저장된 세션에서 복구 시도
                    if let manualSession = await authViewModel.supabaseService.restoreSessionManually() {
                        print("🔍 SSAFYHubApp: 수동 세션 복구 성공 - 사용자 ID: \(manualSession.user.id)")
                        
                        let userData = try await authViewModel.fetchUserData(userId: manualSession.user.id.uuidString)
                        print("🔍 SSAFYHubApp: 사용자 데이터 로드 완료 - \(userData.email)")
                        
                        // 게스트 모드 사용자는 복구하지 않음
                        if userData.userType == .guest {
                            print("👤 게스트 모드 사용자 수동 세션 발견 - 복구하지 않음")
                            print("🔍 SSAFYHubApp: 게스트 모드는 임시 사용자이므로 수동 세션 복구하지 않음")
                        } else {
                            // 사용자 세션 저장
                            await authViewModel.supabaseService.saveUserSession(userData)
                            print("🔍 SSAFYHubApp: 수동 세션 복구 후 사용자 세션 저장 완료 - \(userData.email)")
                            
                            await MainActor.run {
                                print("✅ 앱 시작 시 수동 세션 복구로 로그인 발견: \(userData.email)")
                                authViewModel.authState = .authenticated(userData)
                                
                                print("🏫 기존 캠퍼스 정보: \(userData.campus.displayName)")
                                appCoordinator.navigateToMainMenuWithCampus(userData.campus)
                            }
                            return
                        }
                    }
                    
                    print("🔍 SSAFYHubApp: 모든 세션 복구 시도 실패, 로그아웃 상태로 설정")
                    
                    // 4. 모든 시도 실패 시 로그아웃 상태로 설정
                    await MainActor.run {
                        print("❌ 앱 시작 시 로그인 상태 확인 실패")
                        authViewModel.authState = .unauthenticated
                        appCoordinator.navigateToAuth()
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ 앱 시작 시 로그인 상태 확인 중 예상치 못한 에러: \(error)")
                    print("🔍 에러 타입: \(type(of: error))")
                    print("🔍 에러 설명: \(error.localizedDescription)")
                    
                    authViewModel.authState = .unauthenticated
                    appCoordinator.navigateToAuth()
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: Double = 0.3
    
    var body: some View {
        ZStack {
            // 전체 배경을 새로운 색상으로 설정
            Color(red: 1/255, green: 158/255, blue: 235/255)
                .ignoresSafeArea()
            
            // 로고를 적당한 크기로 중앙에 배치
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                .animation(.easeInOut(duration: 0.8), value: logoOpacity)
                .animation(.easeInOut(duration: 0.8), value: logoScale)
        }
        .onAppear {
            // 로고가 작게 시작해서 부드럽게 커지도록
            withAnimation(.easeInOut(duration: 0.8)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
        }
    }
}

import SwiftUI

@main
struct SSAFYHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appCoordinator.currentRoute {
                case .auth:
                    AuthView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                        .onAppear {
                            // Coordinator 연결
                            authViewModel.setCoordinator(appCoordinator)
                        }
                case .campusSelection:
                    CampusSelectionView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                case .mainMenu:
                    MainMenuView()
                        .environmentObject(authViewModel)
                        .environmentObject(appCoordinator)
                }
            }
            .animation(.easeInOut, value: appCoordinator.currentRoute)
            .onChange(of: authViewModel.authState) { oldValue, newValue in
                print("🔄 SSAFYHubApp에서 authState 변경 감지")
                print("📱 이전 상태: \(oldValue)")
                print("📱 새로운 상태: \(newValue)")
                
                // 인증된 상태인지 확인하고 Coordinator에 알림
                if case .authenticated(let user) = newValue {
                    print("✅ 인증된 사용자: \(user.email) - \(user.campus.displayName)")
                    
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
                checkInitialAuthState()
            }
        }
    }
    
    // MARK: - Initial Auth State Check
    private func checkInitialAuthState() {
        Task {
            do {
                let session = try await authViewModel.supabaseService.client.auth.session
                let user = session.user
                let userData = try await authViewModel.fetchUserData(userId: user.id.uuidString)
                
                await MainActor.run {
                    print("✅ 앱 시작 시 기존 로그인 발견: \(userData.email)")
                    authViewModel.authState = .authenticated(userData)
                    
                    // 기존 사용자는 바로 메인화면으로
                    if !userData.campus.rawValue.isEmpty {
                        print("🏫 기존 캠퍼스 정보: \(userData.campus.displayName)")
                        appCoordinator.navigateToMainMenuWithCampus(userData.campus)
                    } else {
                        print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로")
                        appCoordinator.navigateToCampusSelection()
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ 앱 시작 시 로그인 상태 확인 실패: \(error)")
                    authViewModel.authState = .unauthenticated
                    appCoordinator.currentRoute = .auth
                }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("로딩 중...")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

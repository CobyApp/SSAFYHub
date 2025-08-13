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
                case .settings:
                    SettingsView()
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
                print("🔍 SSAFYHubApp: 세션 상태 확인 시작")
                
                // 1. 먼저 저장된 사용자 세션에서 복구 시도
                if let savedUser = await authViewModel.supabaseService.restoreUserSession() {
                    print("🔍 SSAFYHubApp: 저장된 사용자 세션 발견 - \(savedUser.email)")
                    
                    await MainActor.run {
                        print("✅ 앱 시작 시 저장된 사용자 세션으로 로그인 복구: \(savedUser.email)")
                        authViewModel.authState = .authenticated(savedUser)
                        
                        if !savedUser.campus.rawValue.isEmpty {
                            print("🏫 기존 캠퍼스 정보: \(savedUser.campus.displayName)")
                            appCoordinator.navigateToMainMenuWithCampus(savedUser.campus)
                        } else {
                            print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로")
                            appCoordinator.navigateToCampusSelection()
                        }
                    }
                    return
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
                        
                        if !userData.campus.rawValue.isEmpty {
                            print("🏫 기존 캠퍼스 정보: \(userData.campus.displayName)")
                            appCoordinator.navigateToMainMenuWithCampus(userData.campus)
                        } else {
                            print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로")
                            appCoordinator.navigateToCampusSelection()
                        }
                    }
                } catch {
                    print("🔍 SSAFYHubApp: Supabase 세션 없음, 수동 세션 복구 시도")
                    
                    // 3. 수동 저장된 세션에서 복구 시도
                    if let manualSession = await authViewModel.supabaseService.restoreSessionManually() {
                        print("🔍 SSAFYHubApp: 수동 세션 복구 성공 - 사용자 ID: \(manualSession.user.id)")
                        
                        let userData = try await authViewModel.fetchUserData(userId: manualSession.user.id.uuidString)
                        print("🔍 SSAFYHubApp: 사용자 데이터 로드 완료 - \(userData.email)")
                        
                        // 사용자 세션 저장
                        await authViewModel.supabaseService.saveUserSession(userData)
                        print("🔍 SSAFYHubApp: 수동 세션 복구 후 사용자 세션 저장 완료 - \(userData.email)")
                        
                        await MainActor.run {
                            print("✅ 앱 시작 시 수동 세션 복구로 로그인 발견: \(userData.email)")
                            authViewModel.authState = .authenticated(userData)
                            
                            if !userData.campus.rawValue.isEmpty {
                                print("🏫 기존 캠퍼스 정보: \(userData.campus.displayName)")
                                appCoordinator.navigateToMainMenuWithCampus(userData.campus)
                            } else {
                                print("❓ 캠퍼스 정보 없음, 캠퍼스 선택 화면으로")
                                appCoordinator.navigateToCampusSelection()
                            }
                        }
                        return
                    }
                    
                    print("🔍 SSAFYHubApp: 모든 세션 복구 시도 실패, 로그아웃 상태로 설정")
                    
                    // 4. 모든 시도 실패 시 로그아웃 상태로 설정
                    await MainActor.run {
                        print("❌ 앱 시작 시 로그인 상태 확인 실패")
                        authViewModel.authState = .unauthenticated
                        appCoordinator.currentRoute = .auth
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ 앱 시작 시 로그인 상태 확인 중 예상치 못한 에러: \(error)")
                    print("🔍 에러 타입: \(type(of: error))")
                    print("🔍 에러 설명: \(error.localizedDescription)")
                    
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

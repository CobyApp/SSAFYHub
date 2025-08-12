import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var menuViewModel = MenuViewModel()
    @State private var showMenuEditor = false
    @State private var showSettings = false
    @State private var showGuestAccessAlert = false
    
    // 게스트 사용자 상태 확인
    private var isGuestUser: Bool {
        guard let currentUser = authViewModel.currentUser else { return false }
        return currentUser.isGuest
    }
    
    // 인증된 사용자 상태 확인
    private var isAuthenticatedUser: Bool {
        guard let currentUser = authViewModel.currentUser else { return false }
        return currentUser.isAuthenticated
    }
    
    // 메뉴 편집 접근 시도
    private func attemptMenuEdit() {
        if isAuthenticatedUser {
            showMenuEditor = true
        } else {
            showGuestAccessAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Date Navigation
                    HStack {
                        Button(action: menuViewModel.goToPreviousDay) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(menuViewModel.currentDate, style: .date)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // 사용자 캠퍼스 정보 표시
                            if let currentUser = authViewModel.currentUser {
                                Text(currentUser.campus.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(menuViewModel.selectedCampus.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: menuViewModel.goToNextDay) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Today Button
                    Button(action: menuViewModel.loadTodayMenu) {
                        Text("오늘")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .shadow(radius: 2)
                
                // Menu Content
                ScrollView {
                    VStack(spacing: 20) {
                        // 게스트 사용자 안내 메시지
                        if isGuestUser {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                    Text("게스트 모드 - 제한된 기능")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("현재 게스트 모드로 이용 중입니다")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("메뉴 편집, 등록, 삭제 기능은 Apple ID 로그인 후 이용 가능합니다")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button("Apple ID로 로그인") {
                                    // TODO: Apple 로그인 화면으로 이동
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        if menuViewModel.isLoading {
                            ProgressView("메뉴를 불러오는 중...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                        } else if let menu = menuViewModel.currentMenu {
                            MenuDisplayView(menu: menu)
                        } else {
                            EmptyMenuView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("SSAFYHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 메뉴 편집 버튼 (인증된 사용자만)
                    if isAuthenticatedUser {
                        Button(action: attemptMenuEdit) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    // 게스트 사용자는 버튼 자체를 표시하지 않음
                }
            }
            .sheet(isPresented: $showMenuEditor) {
                // 인증된 사용자만 메뉴 편집 화면 접근 가능
                if isAuthenticatedUser {
                    MenuEditorView(
                        menuViewModel: menuViewModel,
                        date: menuViewModel.currentDate
                    )
                    .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("게스트 모드 제한", isPresented: $showGuestAccessAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("메뉴 편집, 등록, 삭제 기능은 Apple ID 로그인 후 이용 가능합니다.")
            }
        }
        .onAppear {
            // 사용자 캠퍼스 정보로 MenuViewModel 초기화
            if let currentUser = authViewModel.currentUser {
                menuViewModel.selectedCampus = currentUser.campus
                print("🏫 MainMenuView: 사용자 캠퍼스 \(currentUser.campus.displayName)로 초기화")
                
                // 캠퍼스 설정 후 메뉴 로드
                menuViewModel.initializeWithCampus(currentUser.campus)
            }
        }
    }
}

#Preview {
    MainMenuView()
}

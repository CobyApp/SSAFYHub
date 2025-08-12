import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var menuViewModel = MenuViewModel()
    @State private var showMenuEditor = false
    @State private var showSettings = false
    
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
                    Button(action: { showMenuEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showMenuEditor) {
                MenuEditorView(
                    menuViewModel: menuViewModel,
                    date: menuViewModel.currentDate
                )
                .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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

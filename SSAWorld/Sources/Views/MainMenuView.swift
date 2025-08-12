import SwiftUI

struct MainMenuView: View {
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingSettings = false
    @State private var showingMenuEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Date Navigation
                dateNavigationView
                
                // Menu Content
                menuContentView
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(authViewModel: authViewModel)
            }
            .sheet(isPresented: $showingMenuEditor) {
                MenuEditorView(
                    menuViewModel: menuViewModel,
                    date: menuViewModel.currentDate
                )
            }
        }
        .environmentObject(menuViewModel)
        .environmentObject(authViewModel)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SSAFY 점심식단")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(menuViewModel.selectedCampus.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Date Navigation View
    private var dateNavigationView: some View {
        HStack {
            Button(action: {
                if menuViewModel.canGoToPreviousDay {
                    menuViewModel.goToPreviousDay()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(menuViewModel.canGoToPreviousDay ? .primary : .secondary)
            }
            .disabled(!menuViewModel.canGoToPreviousDay)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(menuViewModel.dateDisplayString)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !menuViewModel.isToday {
                    Button("오늘로") {
                        menuViewModel.goToToday()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button(action: {
                if menuViewModel.canGoToNextDay {
                    menuViewModel.goToNextDay()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(menuViewModel.canGoToNextDay ? .primary : .secondary)
            }
            .disabled(!menuViewModel.canGoToNextDay)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Menu Content View
    private var menuContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if menuViewModel.isLoading {
                    ProgressView("메뉴를 불러오는 중...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let menu = menuViewModel.currentMenu {
                    MenuDisplayView(menu: menu)
                } else {
                    EmptyMenuView()
                }
                
                // Add Menu Button
                Button(action: { showingMenuEditor = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("메뉴 추가/수정")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .refreshable {
            menuViewModel.loadMenuForCurrentDate()
        }
    }
}

#Preview {
    MainMenuView()
}

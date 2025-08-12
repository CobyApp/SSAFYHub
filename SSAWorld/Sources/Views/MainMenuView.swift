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

// MARK: - Menu Display View
struct MenuDisplayView: View {
    let menu: Menu
    
    var body: some View {
        VStack(spacing: 16) {
            // A Type Menu
            MenuTypeView(
                title: "A타입",
                items: menu.itemsA,
                color: .blue
            )
            
            // B Type Menu
            MenuTypeView(
                title: "B타입",
                items: menu.itemsB,
                color: .green
            )
            
            // Update Info
            HStack {
                Text("최종 수정: \(menu.updatedAt, style: .relative) 전")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("v\(menu.revision)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Menu Type View
struct MenuTypeView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal)
            
            if items.isEmpty {
                Text("메뉴 정보가 없습니다")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text("•")
                                .foregroundColor(color)
                            Text(item)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Empty Menu View
struct EmptyMenuView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("오늘 메뉴가 등록되지 않았습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("아래 버튼을 눌러 메뉴를 등록해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

#Preview {
    MainMenuView()
}

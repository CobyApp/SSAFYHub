import SwiftUI

struct MainMenuView: View {
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
                            
                            Text(menuViewModel.selectedCampus.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainMenuView()
}

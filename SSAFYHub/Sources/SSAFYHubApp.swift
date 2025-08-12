import SwiftUI

@main
struct SSAFYHubApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch authViewModel.authState {
                case .loading:
                    LoadingView()
                case .unauthenticated:
                    AuthView()
                case .authenticated(_):
                    MainMenuView()
                        .environmentObject(authViewModel)
                }
            }
            .animation(.easeInOut, value: authViewModel.authState)
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

import SwiftUI

@main
struct SSAWorldApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authViewModel.authState {
                case .loading:
                    LoadingView()
                case .authenticated:
                    MainMenuView()
                        .environmentObject(authViewModel)
                case .unauthenticated:
                    AuthView(authViewModel: authViewModel)
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
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("로딩 중...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

import SwiftUI
import ComposableArchitecture

@main
struct SSAFYHubApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            WithViewStore(store, observe: \.auth.isAuthenticated) { viewStore in
                ZStack {
                    if viewStore.state {
                        MainMenuView(store: store)
                    } else {
                        AuthView(store: store.scope(state: \.auth, action: \.auth))
                    }
                }
                .onAppear {
                    print("🚀 SSAFYHubApp: 앱 시작 - isAuthenticated: \(viewStore.state)")
                    viewStore.send(.onAppear)
                }
                .onChange(of: viewStore.state) { oldValue, newValue in
                    print("🔄 SSAFYHubApp: 인증 상태 변경 - \(oldValue) → \(newValue)")
                }
            }
        }
    }
}

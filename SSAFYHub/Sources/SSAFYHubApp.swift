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
                    viewStore.send(.onAppear)
                }
            }
        }
    }
}

import Dependencies
import Foundation
import SharedModels

extension DependencyValues {
    var supabaseService: SupabaseService {
        get { self[SupabaseServiceKey.self] }
        set { self[SupabaseServiceKey.self] = newValue }
    }
    
    var chatGPTService: ChatGPTService {
        get { self[ChatGPTServiceKey.self] }
        set { self[ChatGPTServiceKey.self] = newValue }
    }
    
    var appleSignInService: AppleSignInService {
        get { self[AppleSignInServiceKey.self] }
        set { self[AppleSignInServiceKey.self] = newValue }
    }
    
    var widgetDataService: WidgetDataService {
        get { self[WidgetDataServiceKey.self] }
        set { self[WidgetDataServiceKey.self] = newValue }
    }
}

private enum SupabaseServiceKey: DependencyKey {
    static let liveValue = SupabaseService()
}

private enum ChatGPTServiceKey: DependencyKey {
    static let liveValue = ChatGPTService()
}

private enum AppleSignInServiceKey: @preconcurrency DependencyKey {
    @MainActor
    static let liveValue = AppleSignInService()
}

private enum WidgetDataServiceKey: DependencyKey {
    static let liveValue = WidgetDataService()
}

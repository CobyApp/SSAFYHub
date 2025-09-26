import SwiftUI
import ComposableArchitecture
import SharedModels

struct MainMenuView: View {
    let store: StoreOf<AppFeature>
    @State private var showMenuEditor = false
    @State private var showSettings = false
    @State private var showGuestAccessAlert = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 0) {
                    // 커스텀 헤더
                    headerView(viewStore)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // 메뉴 컨텐츠
                            if let menu = viewStore.menu.currentMenu {
                                // 메뉴가 있지만 내용이 비어있는지 확인
                                let hasMenuA = !menu.itemsA.isEmpty && !menu.itemsA.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                                let hasMenuB = !menu.itemsB.isEmpty && !menu.itemsB.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                                
                                if hasMenuA || hasMenuB {
                                    menuContentView(menu, viewStore)
                                } else {
                                    // 메뉴는 있지만 내용이 비어있음 - 버튼 없이 메시지만 표시
                                    noMenuContentView(viewStore)
                                }
                            } else {
                                // 메뉴가 아예 없음 - 메뉴 등록하기 버튼 표시
                                emptyMenuView(viewStore)
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .background(AppColors.backgroundPrimary)
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                let translation = value.translation
                                if translation.width > threshold {
                                    // 오른쪽으로 스와이프 - 이전 날짜
                                    print("👈 오른쪽 스와이프 - 이전 날짜로 이동")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // 주말 자동 처리: 토/일 → 이전 평일로 이동
                                        let previousDate = getPreviousWeekday(Calendar.current.date(byAdding: .day, value: -1, to: viewStore.menu.currentDate) ?? Date())
                                        viewStore.send(.menu(.dateChanged(previousDate)))
                                    }
                                } else if translation.width < -threshold {
                                    // 왼쪽으로 스와이프 - 다음 날짜
                                    print("👉 왼쪽 스와이프 - 다음 날짜로 이동")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // 주말 자동 처리: 토/일 → 다음 평일로 이동
                                        let nextDate = getNextWeekday(Calendar.current.date(byAdding: .day, value: 1, to: viewStore.menu.currentDate) ?? Date())
                                        viewStore.send(.menu(.dateChanged(nextDate)))
                                    }
                                }
                            }
                    )
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView(
                        store: store.scope(state: \.settings, action: \.settings)
                    )
                    .navigationBarHidden(true)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
                viewStore.send(.menu(.onAppear))
                
                // 주말일 경우 가장 가까운 월요일로 자동 설정
                adjustWeekendDateIfNeeded(viewStore)
            }
            .alert("게스트 모드 제한", isPresented: $showGuestAccessAlert) {
                Button("확인") { }
            } message: {
                Text("게스트 사용자는 메뉴 편집이 제한됩니다. Apple ID로 로그인하여 모든 기능을 이용하세요.")
            }
            .fullScreenCover(isPresented: $showMenuEditor) {
                if let currentUser = viewStore.auth.currentUser, currentUser.isAuthenticated {
                    MenuEditorView(
                        store: store.scope(state: \.menuEditor, action: \.menuEditor)
                    )
                }
            }
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private func headerView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 0) {
            // 상단 설정 버튼과 메인 헤더를 한 줄에 배치
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("식단표")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let currentUser = viewStore.auth.currentUser {
                        Text(currentUser.campus.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("대전캠퍼스")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.backgroundTertiary)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
            
            // 날짜 표시 (화살표 터치 가능, 날짜와 요일 한 줄)
            HStack {
                Button(action: {
                    print("👈 왼쪽 화살표 터치 - 이전 날짜로 이동")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let previousDate = getPreviousWeekday(Calendar.current.date(byAdding: .day, value: -1, to: viewStore.menu.currentDate) ?? Date())
                        viewStore.send(.menu(.dateChanged(previousDate)))
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.backgroundTertiary)
                        .cornerRadius(16)
                }
                .disabled(viewStore.menu.isLoading)
                .opacity(viewStore.menu.isLoading ? 0.5 : 1.0)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(dateString(from: viewStore.menu.currentDate))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("•")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(weekdayString(from: viewStore.menu.currentDate))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    print("👉 오른쪽 화살표 터치 - 다음 날짜로 이동")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let nextDate = getNextWeekday(Calendar.current.date(byAdding: .day, value: 1, to: viewStore.menu.currentDate) ?? Date())
                        viewStore.send(.menu(.dateChanged(nextDate)))
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.backgroundTertiary)
                        .cornerRadius(16)
                }
                .disabled(viewStore.menu.isLoading)
                .opacity(viewStore.menu.isLoading ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Menu Content View
    @ViewBuilder
    private func menuContentView(_ menu: MealMenu, _ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 20) {
            // A타입 메뉴
            if !menu.itemsA.isEmpty && !menu.itemsA.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                menuSection(title: "A타입", items: menu.itemsA, color: AppColors.primary)
            }
            
            // B타입 메뉴
            if !menu.itemsB.isEmpty && !menu.itemsB.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                menuSection(title: "B타입", items: menu.itemsB, color: AppColors.success)
            }
            
            // 메뉴 수정 버튼 (인증된 사용자) 또는 게스트나가기 버튼 (게스트 사용자)
            if let currentUser = viewStore.auth.currentUser {
                if currentUser.isAuthenticated {
                    Button(action: { showMenuEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            Text("메뉴 수정하기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(20)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                } else if currentUser.isGuest {
                    Button(action: {
                        // 게스트 모드 종료
                        viewStore.send(.auth(.exitGuestMode))
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.error)
                            
                            Text("게스트 모드 나가기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.error)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.error)
                        }
                        .padding(20)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Menu Section
    private func menuSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 6, height: 6)
                        
                        Text(item)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(20)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(16)
    }
    
    // MARK: - No Menu Content View (메뉴는 있지만 내용이 비어있음)
    @ViewBuilder
    private func noMenuContentView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 8) {
                    Text("메뉴 없음")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("오늘은 등록된 메뉴가 없습니다")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // 메뉴 수정 버튼 (인증된 사용자) 또는 게스트나가기 버튼 (게스트 사용자)
            if let currentUser = viewStore.auth.currentUser {
                if currentUser.isAuthenticated {
                    Button(action: { showMenuEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primary)
                            
                            Text("메뉴 수정하기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(20)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                } else if currentUser.isGuest {
                    Button(action: {
                        viewStore.send(.auth(.exitGuestMode))
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.error)
                            
                            Text("게스트 모드 나가기")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.error)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.error)
                        }
                        .padding(20)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty Menu View (메뉴를 아직 등록하지 않음)
    @ViewBuilder
    private func emptyMenuView(_ viewStore: ViewStoreOf<AppFeature>) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 8) {
                    Text("오늘 등록된 메뉴가 없습니다")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let currentUser = viewStore.auth.currentUser, currentUser.isAuthenticated {
                        Text("아래 버튼을 눌러 메뉴를 등록해보세요")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("Apple ID로 로그인하여 메뉴를 등록할 수 있습니다")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            // 메뉴 추가 버튼 (인증된 사용자) 또는 게스트나가기 버튼 (게스트 사용자)
            if let currentUser = viewStore.auth.currentUser {
                if currentUser.isAuthenticated {
                    Button(action: { showMenuEditor = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.backgroundPrimary)
                            
                            Text("메뉴 등록하기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.backgroundPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.backgroundPrimary)
                        }
                        .padding(20)
                        .background(AppColors.primary)
                        .cornerRadius(16)
                    }
                } else if currentUser.isGuest {
                    Button(action: {
                        viewStore.send(.auth(.exitGuestMode))
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.backgroundPrimary)
                            
                            Text("게스트 모드 나가기")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.backgroundPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.backgroundPrimary)
                        }
                        .padding(20)
                        .background(AppColors.error)
                        .cornerRadius(16)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
    
    private func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    // 이전 평일 찾기 (토/일 건너뛰기)
    private func getPreviousWeekday(_ date: Date) -> Date {
        let calendar = Calendar.current
        var previousDate = date
        
        // 이전 평일 찾기 (토요일, 일요일 건너뛰기)
        repeat {
            let weekday = calendar.component(.weekday, from: previousDate)
            // weekday: 1=일요일, 2=월요일, ..., 7=토요일
            if weekday != 1 && weekday != 7 { // 일요일과 토요일이 아닌 경우
                break
            }
            
            // 주말이면 이전 날짜로
            if let tempDate = calendar.date(byAdding: .day, value: -1, to: previousDate) {
                previousDate = tempDate
            } else {
                break
            }
        } while true
        
        return previousDate
    }
    
    // 다음 평일 찾기 (토/일 건너뛰기)
    private func getNextWeekday(_ date: Date) -> Date {
        let calendar = Calendar.current
        var nextDate = date
        
        // 다음 평일 찾기 (토요일, 일요일 건너뛰기)
        repeat {
            let weekday = calendar.component(.weekday, from: nextDate)
            // weekday: 1=일요일, 2=월요일, ..., 7=토요일
            if weekday != 1 && weekday != 7 { // 일요일과 토요일이 아닌 경우
                break
            }
            
            // 주말이면 다음 날짜로
            if let tempDate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                nextDate = tempDate
            } else {
                break
            }
        } while true
        
        return nextDate
    }
    
    // 주말 자동 처리: 토/일 → 다음 월요일로 이동 (기존 함수 유지)
    private func getAdjustedDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 토요일(7) 또는 일요일(1)인 경우 다음 월요일로 이동
        if weekday == 1 { // 일요일
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        } else if weekday == 7 { // 토요일
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
        }
        
        return date
    }
    
    // 주말일 경우 가장 가까운 월요일로 자동 설정
    private func adjustWeekendDateIfNeeded(_ viewStore: ViewStoreOf<AppFeature>) {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // 주말이면 가장 가까운 월요일로 설정
        if weekday == 1 { // 일요일
            // 다음 주 월요일
            if let nextMonday = calendar.date(byAdding: .day, value: 1, to: today) {
                let mondayDate = calendar.startOfDay(for: nextMonday)
                if mondayDate != viewStore.menu.currentDate {
                    print("📅 일요일 감지 - 다음 주 월요일로 자동 이동: \(mondayDate)")
                    viewStore.send(.menu(.dateChanged(mondayDate)))
                }
            }
        } else if weekday == 7 { // 토요일
            // 다음 주 월요일
            if let nextMonday = calendar.date(byAdding: .day, value: 2, to: today) {
                let mondayDate = calendar.startOfDay(for: nextMonday)
                if mondayDate != viewStore.menu.currentDate {
                    print("📅 토요일 감지 - 다음 주 월요일로 자동 이동: \(mondayDate)")
                    viewStore.send(.menu(.dateChanged(mondayDate)))
                }
            }
        } else {
            // 평일이면 오늘 날짜로 설정 (시간 제거)
            let todayDate = calendar.startOfDay(for: today)
            if todayDate != viewStore.menu.currentDate {
                print("📅 평일 감지 - 오늘 날짜로 설정: \(todayDate)")
                viewStore.send(.menu(.dateChanged(todayDate)))
            }
        }
    }
}

#Preview {
    MainMenuView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}


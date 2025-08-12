import SwiftUI
import PhotosUI

struct MenuEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let menuViewModel: MenuViewModel
    let date: Date
    
    @State private var itemsA: [String] = []
    @State private var itemsB: [String] = []
    @State private var isWeeklyMode = false
    @State private var weeklyItemsA: [[String]] = Array(repeating: [], count: 5)
    @State private var weeklyItemsB: [[String]] = Array(repeating: [], count: 5)
    @State private var selectedDate = Date()  // 선택된 날짜
    @State private var selectedWeekStart = Date()  // 선택된 주의 시작일
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 주간 날짜 계산 (월요일~금요일)
    private var weeklyDates: [Date] {
        let calendar = Calendar.current
        
        // selectedWeekStart에서 가장 가까운 월요일을 찾기
        let weekday = calendar.component(.weekday, from: selectedWeekStart)
        let daysToMonday = weekday == 1 ? 1 : (9 - weekday) % 7 // 일요일이면 다음 월요일, 그 외에는 이번 주 월요일
        
        guard let monday = calendar.date(byAdding: .day, value: daysToMonday, to: selectedWeekStart) else {
            return []
        }
        
        // 월요일부터 5일 (월~금)
        return (0..<5).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monday)
        }
    }
    
    // 선택된 날짜가 월~금인지 확인
    private var isSelectedDateValid: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        // 월요일(2) ~ 금요일(6)
        return weekday >= 2 && weekday <= 6
    }
    
    // 선택된 주가 월~금인지 확인
    private var isSelectedWeekValid: Bool {
        let calendar = Calendar.current
        return weeklyDates.allSatisfy { date in
            let weekday = calendar.component(.weekday, from: date)
            return weekday >= 2 && weekday <= 6
        }
    }
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingImage = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    private let ocrService = OCRService.shared
    @StateObject private var permissionChecker = PermissionChecker()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 모드 토글 (게스트 사용자는 단일 모드만 가능)
                    if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                        modeToggleView
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    // 날짜 선택 헤더
                    dateSelectionHeader
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // 메뉴 입력 폼
                    if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                        // 인증된 사용자: 주간/단일 모드 선택 가능
                        if isWeeklyMode {
                            weeklyMenuInputFormsView
                                .padding(.horizontal, AppSpacing.lg)
                        } else {
                            singleMenuInputFormsView
                                .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        // OCR 기능 버튼들
                        ocrButtonsView
                            .padding(.horizontal, AppSpacing.lg)
                    } else {
                        // 게스트 사용자: 읽기 전용
                        guestReadOnlyView
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                    
                    // 저장 버튼 (게스트 사용자는 숨김)
                    if let currentUser = authViewModel.currentUser, currentUser.isAuthenticated {
                        saveButtonView
                            .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("메뉴 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    processImage(image)
                }
            }
            .alert("알림", isPresented: $showingAlert) {
                Button("확인") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            // 초기 날짜 설정
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            
            // 오늘이 주말이면 다음 월요일로 설정
            if weekday == 1 { // 일요일
                selectedDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            } else if weekday == 7 { // 토요일
                selectedDate = calendar.date(byAdding: .day, value: 2, to: today) ?? today
            } else {
                selectedDate = today
            }
            
            // 주간 모드 초기화: 현재 날짜가 포함된 주의 월요일부터 시작
            selectedWeekStart = selectedDate
            
            print("📅 MenuEditorView 초기화")
            print("📅 오늘: \(today)")
            print("📅 선택된 날짜: \(selectedDate)")
            print("📅 주 시작일: \(selectedWeekStart)")
            print("📅 주간 날짜들: \(weeklyDates.map { $0.formatted(date: .abbreviated, time: .omitted) })")
            
            loadExistingMenu()
        }
        .alert("알림", isPresented: $showingAlert) {
            Button("확인") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Mode Toggle View
    private var modeToggleView: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("메뉴 등록 모드")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.sm) {
                Button(action: { isWeeklyMode = false }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("단일")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(isWeeklyMode ? AppColors.textSecondary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        isWeeklyMode ? AppColors.backgroundSecondary : AppColors.primary
                    )
                    .cornerRadius(AppCornerRadius.medium)
                }
                
                Button(action: { isWeeklyMode = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("주간")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(isWeeklyMode ? .white : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        isWeeklyMode ? AppColors.primary : AppColors.backgroundSecondary
                    )
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppCornerRadius.medium)
    }
    
    // MARK: - Date Selection Header
    private var dateSelectionHeader: some View {
        VStack(spacing: 20) {
            if isWeeklyMode {
                // 주간 모드: 주 선택
                VStack(spacing: 16) {
                    Text("주간 메뉴 등록")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 20) {
                        Button(action: selectPreviousWeek) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 40, height: 40)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(20)
                        }
                        
                        VStack(spacing: 8) {
                            Text(weekRangeText)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("월~금 5일을 한번에 등록합니다")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Button(action: selectNextWeek) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 40, height: 40)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
            } else {
                // 단일 모드: 날짜 선택
                VStack(spacing: 16) {
                    Text("단일 메뉴 등록")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: 12) {
                        DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .onChange(of: selectedDate) { _, newDate in
                                // 월~금만 선택 가능하도록 제한
                                if !isSelectedDateValid {
                                    // 월~금이 아닌 날짜 선택 시 다음 월요일로 조정
                                    adjustToNextMonday(newDate)
                                }
                            }
                        
                        Text(selectedDateText)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.primary)
                        
                        Text("월~금 중 하루를 선택하세요")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
    
    // 주 범위 텍스트 (월~금)
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        
        let monday = weeklyDates.first ?? selectedWeekStart
        let friday = weeklyDates.last ?? selectedWeekStart
        
        return "\(formatter.string(from: monday)) ~ \(formatter.string(from: friday))"
    }
    
    // 선택된 날짜 한글 표시
    private var selectedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: selectedDate)
    }
    
    // 이전 주 선택
    private func selectPreviousWeek() {
        let calendar = Calendar.current
        if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) {
            selectedWeekStart = newWeekStart
        }
    }
    
    // 다음 주 선택
    private func selectNextWeek() {
        let calendar = Calendar.current
        if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) {
            selectedWeekStart = newWeekStart
        }
    }
    
    // 월요일로 조정
    private func adjustToNextMonday(_ date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        if weekday == 1 { // 일요일
            // 다음 월요일로
            if let nextMonday = calendar.date(byAdding: .day, value: 1, to: date) {
                selectedDate = nextMonday
            }
        } else if weekday == 7 { // 토요일
            // 다음 월요일로
            if let nextMonday = calendar.date(byAdding: .day, value: 2, to: date) {
                selectedDate = nextMonday
            }
        }
    }
    
    // MARK: - OCR Buttons View
    private var ocrButtonsView: some View {
        VStack(spacing: 16) {
            Text("메뉴 인식")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                // 카메라 버튼
                Button(action: { checkCameraPermission() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("카메라")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                
                // 앨범 버튼
                Button(action: { checkPhotoLibraryPermission() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("앨범")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primary, lineWidth: 1)
                    )
                }
            }
            
            if isProcessingImage {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("이미지 처리 중...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            permissionChecker.checkCameraPermission()
            permissionChecker.checkPhotoLibraryPermission()
        }
        .alert("권한 필요", isPresented: $showingPermissionAlert) {
            Button("설정으로 이동") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    // MARK: - Single Menu Input Forms View
    private var singleMenuInputFormsView: some View {
        VStack(spacing: 20) {
            // A Type Input
            MenuTypeInputView(
                title: "A타입",
                items: $itemsA,
                color: .blue
            )
            
            // B Type Input
            MenuTypeInputView(
                title: "B타입",
                items: $itemsB,
                color: .green
            )
        }
    }
    
    // MARK: - Weekly Menu Input Forms View
    private var weeklyMenuInputFormsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(index + 1)일차")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(weeklyDates[index], style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // A Type Input
                        MenuTypeInputView(
                            title: "A타입",
                            items: $weeklyItemsA[index],
                            color: .blue
                        )
                        
                        // B Type Input
                        MenuTypeInputView(
                            title: "B타입",
                            items: $weeklyItemsB[index],
                            color: .green
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Save Button View
    private var saveButtonView: some View {
        Button(action: saveMenu) {
            HStack {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "저장 중..." : "저장")
            }
            .font(AppTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(hasValidMenuData ? AppColors.primary : AppColors.textTertiary)
            .cornerRadius(AppCornerRadius.pill)
            .shadow(
                color: hasValidMenuData ? AppColors.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!hasValidMenuData || isSaving)
        .scaleEffect(hasValidMenuData ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: hasValidMenuData)
    }
    
    // MARK: - Menu Validation
    private var hasValidMenuData: Bool {
        if isWeeklyMode {
            // 주간 모드: 최소 하나의 메뉴라도 입력되어야 함
            return weeklyItemsA.enumerated().contains { index, items in
                !items.isEmpty || !weeklyItemsB[index].isEmpty
            }
        } else {
            // 단일 모드: A타입 또는 B타입 중 하나라도 입력되어야 함
            return !itemsA.isEmpty || !itemsB.isEmpty
        }
    }
    
    // MARK: - Save Menu
    private func saveMenu() {
        guard hasValidMenuData else {
            alertMessage = "메뉴를 하나 이상 입력해주세요."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                if isWeeklyMode {
                    try await saveWeeklyMenu()
                } else {
                    try await saveSingleMenu()
                }
            } catch {
                await MainActor.run {
                    print("❌ 메뉴 저장 실패: \(error)")
                    isSaving = false
                    alertMessage = "메뉴 저장에 실패했습니다: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Save Single Menu
    private func saveSingleMenu() async throws {
        let menuInput = MenuInput(
            date: selectedDate,  // 선택된 날짜 사용
            campus: menuViewModel.selectedCampus,
            itemsA: itemsA,
            itemsB: itemsB
        )
        
        let updatedBy = authViewModel.currentUser?.email ?? "unknown"
        
        print("💾 단일 메뉴 저장 시작")
        print("📅 선택된 날짜: \(selectedDate)")
        print("🏫 캠퍼스: \(menuViewModel.selectedCampus.displayName)")
        print("🍽️ A타입: \(itemsA)")
        print("🍽️ B타입: \(itemsB)")
        print("👤 수정자: \(updatedBy)")
        
        try await menuViewModel.supabaseService.saveMenu(menuInput: menuInput, updatedBy: updatedBy)
        
        await MainActor.run {
            print("✅ 단일 메뉴 저장 성공")
            isSaving = false
            
            // 성공 메시지 표시 후 화면 닫기
            alertMessage = "메뉴가 성공적으로 저장되었습니다!"
            showingAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
    
    // MARK: - Save Weekly Menu
    private func saveWeeklyMenu() async throws {
        let dailyMenus = weeklyDates.enumerated().map { index, date in
            DailyMenu(
                date: date,
                itemsA: weeklyItemsA[index],
                itemsB: weeklyItemsB[index]
            )
        }
        
        let weeklyInput = WeeklyMenuInput(
            startDate: weeklyDates.first ?? selectedWeekStart,
            campus: menuViewModel.selectedCampus,
            weeklyMenus: dailyMenus
        )
        
        let updatedBy = authViewModel.currentUser?.email ?? "unknown"
        
        print("💾 주간 메뉴 저장 시작")
        print("📅 선택된 주: \(weekRangeText)")
        print("🏫 캠퍼스: \(weeklyInput.campus.displayName)")
        print("🍽️ 총 메뉴 수: \(dailyMenus.count)일")
        print("👤 수정자: \(updatedBy)")
        
        try await menuViewModel.supabaseService.saveWeeklyMenu(weeklyInput: weeklyInput, updatedBy: updatedBy)
        
        await MainActor.run {
            print("✅ 주간 메뉴 저장 성공")
            isSaving = false
            
            // 성공 메시지 표시 후 화면 닫기
            alertMessage = "주간 메뉴가 성공적으로 저장되었습니다!"
            showingAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadExistingMenu() {
        if isWeeklyMode {
            // 주간 모드에서는 기존 메뉴를 각 일자별로 로드
            loadWeeklyExistingMenus()
        } else {
            // 단일 모드에서는 현재 날짜의 메뉴만 로드
            loadSingleExistingMenu()
        }
    }
    
    private func loadSingleExistingMenu() {
        if let menu = menuViewModel.currentMenu {
            itemsA = menu.itemsA
            itemsB = menu.itemsB
            print("📋 단일 메뉴 로드됨 - A타입: \(itemsA.count)개, B타입: \(itemsB.count)개")
        } else {
            print("📋 해당 날짜에 기존 메뉴 없음")
            // 기존 메뉴가 없으면 빈 배열로 초기화
            itemsA = []
            itemsB = []
        }
    }
    
    private func loadWeeklyExistingMenus() {
        print("📋 주간 메뉴 로드 시작")
        
        // 각 일자별로 기존 메뉴 로드
        for (index, weekDate) in weeklyDates.enumerated() {
            Task {
                do {
                    print("📋 \(index + 1)일차 메뉴 로드 중: \(weekDate)")
                    if let menu = try await menuViewModel.supabaseService.fetchMenu(date: weekDate, campus: menuViewModel.selectedCampus) {
                        await MainActor.run {
                            weeklyItemsA[index] = menu.itemsA
                            weeklyItemsB[index] = menu.itemsB
                            print("✅ \(index + 1)일차 메뉴 로드 완료 - A타입: \(menu.itemsA.count)개, B타입: \(menu.itemsB.count)개")
                        }
                    } else {
                        await MainActor.run {
                            // 기존 메뉴가 없으면 빈 배열로 초기화
                            weeklyItemsA[index] = []
                            weeklyItemsB[index] = []
                            print("📭 \(index + 1)일차 기존 메뉴 없음")
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("❌ \(index + 1)일차 메뉴 로드 실패: \(error)")
                        // 에러 발생 시 빈 배열로 초기화
                        weeklyItemsA[index] = []
                        weeklyItemsB[index] = []
                    }
                }
            }
        }
    }
    
    // MARK: - Image Processing
    private func processImage(_ image: UIImage) {
        isProcessingImage = true
        
        Task {
            do {
                let extractedText = try await ocrService.extractTextFromImage(image)
                print("🔍 OCR 결과: \(extractedText)")
                
                await MainActor.run {
                    // OCR 결과를 메뉴 입력 필드에 자동으로 채우기
                    if isWeeklyMode {
                        // 주간 모드: 첫 번째 날짜에만 적용
                        let lines = extractedText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        weeklyItemsA[0] = lines
                    } else {
                        // 단일 모드: A타입에 적용
                        let lines = extractedText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        itemsA = lines
                    }
                    
                    isProcessingImage = false
                    selectedImage = nil
                    
                    // 성공 메시지 표시
                    alertMessage = "메뉴 인식이 완료되었습니다!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isProcessingImage = false
                    selectedImage = nil
                    
                    // 에러 메시지 표시
                    alertMessage = "메뉴 인식에 실패했습니다: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Guest Read Only View
    private var guestReadOnlyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("게스트 사용자는 메뉴를 편집할 수 없습니다")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Apple ID로 로그인하여 메뉴 편집 기능을 이용하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Apple 로그인") {
                // Apple 로그인 화면으로 이동
                dismiss()
                // TODO: Apple 로그인 화면으로 네비게이션
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
    
    private func checkCameraPermission() {
        if permissionChecker.cameraPermissionGranted {
            showingCamera = true
        } else {
            permissionChecker.checkCameraPermission()
            if !permissionChecker.cameraPermissionGranted {
                showingPermissionAlert = true
                permissionAlertMessage = "카메라 접근 권한이 필요합니다. 설정에서 허용해주세요."
            }
        }
    }
    
    private func checkPhotoLibraryPermission() {
        if permissionChecker.photoLibraryPermissionGranted {
            showingImagePicker = true
        } else {
            permissionChecker.checkPhotoLibraryPermission()
            if !permissionChecker.photoLibraryPermissionGranted {
                showingPermissionAlert = true
                permissionAlertMessage = "앨범 접근 권한이 필요합니다. 설정에서 허용해주세요."
            }
        }
    }
}

#Preview {
    MenuEditorView(
        menuViewModel: MenuViewModel(),
        date: Date()
    )
    .environmentObject(AuthViewModel())
}

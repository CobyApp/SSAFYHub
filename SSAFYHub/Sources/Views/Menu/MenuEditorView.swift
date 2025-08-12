import SwiftUI
import PhotosUI

struct MenuEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let menuViewModel: MenuViewModel
    let date: Date
    
    // 주간 메뉴만 사용하므로 단일 메뉴 관련 상태 제거
    @State private var weeklyItemsA: [[String]] = Array(repeating: [], count: 5)
    @State private var weeklyItemsB: [[String]] = Array(repeating: [], count: 5)
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
    @StateObject private var geminiService = ChatGPTService.shared  // ChatGPTService로 변경
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 날짜 선택 헤더
                    dateSelectionHeader
                    
                    // OCR 버튼 (주간 모드에서만 표시)
                    ocrButtonsView
                    
                    // 주간 메뉴 입력 섹션
                    weeklyMenuSection
                }
                .padding(AppSpacing.lg)
            }
            .navigationTitle("주간 메뉴 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        saveMenu()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        processImage(image)
                    }
                }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        processImage(image)
                    }
                }
        }
        .onAppear {
            permissionChecker.checkCameraPermission()
            permissionChecker.checkPhotoLibraryPermission()
            
            // 현재 날짜로 주 시작일 초기화
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            
            // 오늘이 주말이면 다음 주 월요일로, 평일이면 이번 주 월요일로 설정
            if weekday == 1 { // 일요일
                // 다음 주 월요일
                if let nextMonday = calendar.date(byAdding: .day, value: 1, to: today) {
                    selectedWeekStart = nextMonday
                }
            } else if weekday == 7 { // 토요일
                // 다음 주 월요일
                if let nextMonday = calendar.date(byAdding: .day, value: 2, to: today) {
                    selectedWeekStart = nextMonday
                }
            } else {
                // 평일이면 이번 주 월요일
                let daysFromMonday = weekday - 2 // 월요일이면 0, 화요일이면 1, ...
                if let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) {
                    selectedWeekStart = monday
                }
            }
            
            // 기본 메뉴 항목 초기화
            initializeMenuItems()
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
    
    // MARK: - Date Selection Header
    private var dateSelectionHeader: some View {
        VStack(spacing: AppSpacing.lg) {
            // 주간 모드: 주 선택
            VStack(spacing: AppSpacing.md) {
                Text("주간 메뉴 등록")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.lg) {
                    Button(action: selectPreviousWeek) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppCornerRadius.pill)
                    }
                    
                    VStack(spacing: AppSpacing.sm) {
                        Text(weekRangeText)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("월~금 5일을 한번에 등록합니다")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Button(action: selectNextWeek) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(AppCornerRadius.pill)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppCornerRadius.large)
        .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
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
    
    // MARK: - OCR Buttons View
    private var ocrButtonsView: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                Text("AI 메뉴 인식")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("주간 식단표 사진을 촬영하거나 선택하면\nAI가 자동으로 메뉴를 인식합니다")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            
            HStack(spacing: AppSpacing.lg) {
                // 카메라 버튼
                Button(action: { checkCameraPermission() }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("카메라")
                            .font(AppTypography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primary)
                    .cornerRadius(AppCornerRadius.medium)
                    .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
                }
                
                // 앨범 버튼
                Button(action: { checkPhotoLibraryPermission() }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("앨범")
                            .font(AppTypography.headline)
                    }
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white)
                    .cornerRadius(AppCornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
                    .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
                }
            }
            
            if isProcessingImage {
                HStack(spacing: AppSpacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppColors.primary)
                    
                    Text("AI가 메뉴를 분석하고 있습니다...")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(AppCornerRadius.medium)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppCornerRadius.large)
        .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
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
    
    // MARK: - Weekly Menu Section
    private var weeklyMenuSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // 주간 메뉴 입력 폼
            ForEach(0..<5, id: \.self) { dayIndex in
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("\(weeklyDates[dayIndex].formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // A타입 메뉴
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("A타입")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                weeklyItemsA[dayIndex].append("")
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(weeklyItemsA[dayIndex].indices, id: \.self) { itemIndex in
                                HStack {
                                    TextField("메뉴를 입력하세요", text: $weeklyItemsA[dayIndex][itemIndex])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button(action: {
                                        weeklyItemsA[dayIndex].remove(at: itemIndex)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(AppColors.error)
                                            .font(.system(size: 18))
                                    }
                                    .disabled(weeklyItemsA[dayIndex].count <= 1)
                                }
                            }
                        }
                    }
                    
                    // B타입 메뉴
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("B타입")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                weeklyItemsB[dayIndex].append("")
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(weeklyItemsB[dayIndex].indices, id: \.self) { itemIndex in
                                HStack {
                                    TextField("메뉴를 입력하세요", text: $weeklyItemsB[dayIndex][itemIndex])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button(action: {
                                        weeklyItemsB[dayIndex].remove(at: itemIndex)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(AppColors.error)
                                            .font(.system(size: 18))
                                    }
                                    .disabled(weeklyItemsB[dayIndex].count <= 1)
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppCornerRadius.medium)
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
        // 주간 모드: 최소 하나의 메뉴라도 입력되어야 함
        return weeklyItemsA.enumerated().contains { index, items in
            !items.isEmpty || !weeklyItemsB[index].isEmpty
        }
    }
    
    // MARK: - Save Menu Function
    private func saveMenu() {
        print("💾 메뉴 저장 시작")
        
        saveWeeklyMenu()
    }
    
    // MARK: - Save Weekly Menu
    private func saveWeeklyMenu() {
        print("💾 주간 메뉴 저장 시작")
        print("📅 주 시작일: \(selectedWeekStart)")
        print("🏫 캠퍼스: \(Campus.default.displayName)")
        
        // 각 날짜별로 메뉴 저장
        Task {
            do {
                for (index, date) in weeklyDates.enumerated() {
                    let itemsA = weeklyItemsA[index]
                    let itemsB = weeklyItemsB[index]
                    
                    // 빈 메뉴는 건너뛰기
                    guard !itemsA.isEmpty || !itemsB.isEmpty else {
                        print("⚠️ \(date.formatted(date: .abbreviated, time: .omitted)) 메뉴가 비어있음")
                        continue
                    }
                    
                    print("📅 \(date.formatted(date: .abbreviated, time: .omitted)) 메뉴 저장")
                    print("🍽️ A타입: \(itemsA)")
                    print("🍽️ B타입: \(itemsB)")
                    
                    // SupabaseService를 통해 저장
                    try await menuViewModel.supabaseService.saveMenu(
                        menuInput: MenuInput(
                            date: date,
                            campus: Campus.default,
                            itemsA: itemsA,
                            itemsB: itemsB
                        ),
                        updatedBy: authViewModel.currentUser?.email
                    )
                    
                    print("✅ \(date.formatted(date: .abbreviated, time: .omitted)) 메뉴 저장 완료")
                }
                
                // 모든 저장 완료 후 화면 닫기
                await MainActor.run {
                    print("✅ 주간 메뉴 저장 완료")
                    dismiss()
                }
            } catch {
                print("❌ 주간 메뉴 저장 실패: \(error)")
                // TODO: 에러 처리
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadExistingMenu() {
        // 주간 모드에서는 기존 메뉴를 각 일자별로 로드
        loadWeeklyExistingMenus()
    }
    
    // 주간 메뉴 로드
    private func loadWeeklyExistingMenus() {
        print("📋 주간 메뉴 로드 시작")
        print("📅 주 시작일: \(selectedWeekStart)")
        print("🏫 캠퍼스: \(Campus.default.displayName)")
        
        // 각 날짜별로 기존 메뉴 로드 또는 기본값 설정
        for (index, weekDate) in weeklyDates.enumerated() {
            print("📋 \(index + 1)일차 메뉴 로드 중: \(weekDate)")
            
            // 기존 메뉴가 있으면 유지, 없으면 기본값 설정
            if weeklyItemsA[index].isEmpty {
                weeklyItemsA[index] = [""]
            }
            if weeklyItemsB[index].isEmpty {
                weeklyItemsB[index] = [""]
            }
            
            print("✅ \(index + 1)일차 메뉴 로드 완료 - A타입: \(weeklyItemsA[index].count)개, B타입: \(weeklyItemsB[index].count)개")
        }
        
        print("✅ 주간 메뉴 로드 완료")
    }
    
    // MARK: - 이미지 처리
    private func processImage(_ image: UIImage) {
        isProcessingImage = true
        selectedImage = nil
        
        Task {
            do {
                print("🔍 ChatGPT API로 메뉴 이미지 분석 시작")
                let extractedMenus = try await geminiService.analyzeMenuImage(image)
                
                await MainActor.run {
                    // 추출된 데이터로 입력 필드 채우기
                    applyExtractedMenuData(extractedMenus)
                    isProcessingImage = false
                    print("✅ 메뉴 데이터 추출 완료")
                }
            } catch {
                await MainActor.run {
                    isProcessingImage = false
                    print("❌ 메뉴 데이터 추출 실패: \(error)")
                    
                    // 사용자 친화적인 에러 메시지 표시
                    if let chatGPTError = error as? ChatGPTError {
                        switch chatGPTError {
                        case .apiRequestFailed:
                            alertMessage = "ChatGPT API 서비스가 일시적으로 사용할 수 없습니다.\n\n무료 사용량 제한에 도달했거나 서버가 혼잡합니다.\n\n잠시 후 다시 시도하거나, 수동으로 메뉴를 입력해주세요."
                        case .imageConversionFailed:
                            alertMessage = "이미지 변환에 실패했습니다.\n\n다른 이미지를 선택하거나 다시 촬영해주세요."
                        case .noContentReceived:
                            alertMessage = "이미지에서 메뉴 정보를 추출할 수 없습니다.\n\n더 선명한 이미지나 다른 각도에서 촬영해주세요."
                        case .parsingFailed:
                            alertMessage = "AI가 추출한 메뉴 정보를 처리할 수 없습니다.\n\n수동으로 메뉴를 입력해주세요."
                        }
                    } else {
                        alertMessage = "메뉴 데이터 추출에 실패했습니다.\n\n\(error.localizedDescription)"
                    }
                    
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - 추출된 메뉴 데이터 적용
    private func applyExtractedMenuData(_ extractedMenus: [Menu]) {
        guard !extractedMenus.isEmpty else { return }
        
        // 첫 번째 메뉴의 날짜를 기준으로 주 시작일 설정
        let firstMenu = extractedMenus[0]
        let calendar = Calendar.current
        
        // 해당 날짜가 포함된 주의 월요일 찾기
        let weekday = calendar.component(.weekday, from: firstMenu.date)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2 // 일요일이면 6일 전, 월요일이면 0일 전
        
        if let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: firstMenu.date) {
            selectedWeekStart = monday
        }
        
        // 각 메뉴를 해당하는 주간 배열에 적용
        for (index, menu) in extractedMenus.enumerated() {
            if index < weeklyItemsA.count && index < weeklyItemsB.count {
                weeklyItemsA[index] = menu.itemsA
                weeklyItemsB[index] = menu.itemsB
            }
        }
        
        print("📋 추출된 메뉴 데이터 적용 완료")
        print("📅 주 시작일: \(selectedWeekStart)")
        print("🍽️ 메뉴 개수: \(extractedMenus.count)일")
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
    
    // 기본 메뉴 항목 초기화
    private func initializeMenuItems() {
        // 주간 모드에서는 기존 메뉴가 있으면 로드하고, 없으면 빈 배열로 초기화
        loadWeeklyExistingMenus()
    }
}

#Preview {
    MenuEditorView(
        menuViewModel: MenuViewModel(),
        date: Date()
    )
    .environmentObject(AuthViewModel())
}

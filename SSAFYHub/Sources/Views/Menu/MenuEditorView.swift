import SwiftUI
import PhotosUI

struct MenuEditorView: View {
    @ObservedObject var menuViewModel: MenuViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let date: Date
    
    @State private var itemsA: [String] = []
    @State private var itemsB: [String] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingImage = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    @State private var isWeeklyMode = false
    @State private var weeklyItemsA: [[String]] = Array(repeating: [], count: 5)
    @State private var weeklyItemsB: [[String]] = Array(repeating: [], count: 5)
    
    @Environment(\.dismiss) private var dismiss
    
    private let ocrService = OCRService.shared
    
    // 주간 날짜 계산
    private var weeklyDates: [Date] {
        let calendar = Calendar.current
        let weekdays = [1, 2, 3, 4, 5] // 월~금
        
        return weekdays.compactMap { weekday in
            calendar.date(byAdding: .day, value: weekday - calendar.component(.weekday, from: date), to: date)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Mode Toggle
                modeToggleView
                
                // Date Header
                dateHeaderView
                
                // OCR Buttons
                ocrButtonsView
                
                // Menu Input Forms
                if isWeeklyMode {
                    weeklyMenuInputFormsView
                } else {
                    singleMenuInputFormsView
                }
                
                Spacer()
                
                // Save Button
                saveButtonView
            }
            .padding()
            .navigationTitle(isWeeklyMode ? "주간 메뉴 편집" : "메뉴 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
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
            .onAppear {
                loadExistingMenu()
            }
        }
    }
    
    // MARK: - Mode Toggle View
    private var modeToggleView: some View {
        HStack {
            Button(action: { 
                isWeeklyMode = false
                // 모드 전환 시 기존 데이터 로드
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadExistingMenu()
                }
            }) {
                Text("하루")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isWeeklyMode ? .secondary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isWeeklyMode ? Color(.systemGray5) : Color.blue)
                    .cornerRadius(20)
            }
            
            Button(action: { 
                isWeeklyMode = true
                // 모드 전환 시 기존 데이터 로드
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadExistingMenu()
                }
            }) {
                Text("주간")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isWeeklyMode ? .white : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isWeeklyMode ? Color.green : Color(.systemGray5))
                    .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Date Header View
    private var dateHeaderView: some View {
        VStack(spacing: 8) {
            if isWeeklyMode {
                Text("\(weeklyDates.first?.formatted(date: .abbreviated, time: .omitted) ?? "") ~ \(weeklyDates.last?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Text(date, style: .date)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text(menuViewModel.selectedCampus.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - OCR Buttons View
    private var ocrButtonsView: some View {
        HStack(spacing: 16) {
            Button(action: { showingCamera = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("사진 촬영")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Button(action: { showingImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("앨범 선택")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "저장 중..." : "저장")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(isSaving || !hasValidMenuData)
    }
    
    // MARK: - Validation
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
    
    private func processImage(_ image: UIImage) {
        isProcessingImage = true
        
        Task {
            do {
                let text = try await ocrService.extractTextFromImage(image)
                let parsedMenu = ocrService.parseMenuFromText(text)
                
                await MainActor.run {
                    if isWeeklyMode {
                        // 주간 모드: 모든 일자에 동일한 메뉴 적용
                        for index in 0..<5 {
                            weeklyItemsA[index] = parsedMenu.itemsA
                            weeklyItemsB[index] = parsedMenu.itemsB
                        }
                        print("📸 OCR 결과를 5일치에 적용 - A타입: \(parsedMenu.itemsA.count)개, B타입: \(parsedMenu.itemsB.count)개")
                    } else {
                        // 단일 모드: 현재 메뉴에만 적용
                        itemsA = parsedMenu.itemsA
                        itemsB = parsedMenu.itemsB
                        print("📸 OCR 결과 - A타입: \(parsedMenu.itemsA.count)개, B타입: \(parsedMenu.itemsB.count)개")
                    }
                    
                    isProcessingImage = false
                    selectedImage = nil
                    
                    if parsedMenu.itemsA.isEmpty && parsedMenu.itemsB.isEmpty {
                        alertMessage = "이미지에서 메뉴를 인식할 수 없습니다. 직접 입력해주세요."
                        showingAlert = true
                    } else {
                        alertMessage = "이미지에서 메뉴를 인식했습니다. 필요에 따라 수정해주세요."
                        showingAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingImage = false
                    selectedImage = nil
                    alertMessage = "이미지 처리에 실패했습니다: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
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
    
    private func saveSingleMenu() async throws {
        let menuInput = MenuInput(
            date: date,
            campus: menuViewModel.selectedCampus,
            itemsA: itemsA,
            itemsB: itemsB
        )
        
        let updatedBy = authViewModel.currentUser?.email ?? "unknown"
        
        print("💾 단일 메뉴 저장 시작")
        print("📅 날짜: \(date)")
        print("🏫 캠퍼스: \(menuViewModel.selectedCampus.displayName)")
        print("🍽️ A타입: \(itemsA)")
        print("🍽️ B타입: \(itemsB)")
        print("👤 수정자: \(updatedBy)")
        
        try await menuViewModel.supabaseService.saveMenu(menuInput: menuInput, updatedBy: updatedBy)
        
        await MainActor.run {
            print("✅ 단일 메뉴 저장 성공")
            isSaving = false
            
            // 현재 편집 중인 날짜의 메뉴 새로고침
            menuViewModel.currentDate = date
            menuViewModel.loadMenuForCurrentDate()
            
            // 성공 메시지 표시 후 화면 닫기
            alertMessage = "메뉴가 성공적으로 저장되었습니다!"
            showingAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
    
    private func saveWeeklyMenu() async throws {
        let dailyMenus = weeklyDates.enumerated().map { index, date in
            DailyMenu(
                date: date,
                itemsA: weeklyItemsA[index],
                itemsB: weeklyItemsB[index]
            )
        }
        
        let weeklyInput = WeeklyMenuInput(
            startDate: weeklyDates.first ?? date,
            campus: menuViewModel.selectedCampus,
            weeklyMenus: dailyMenus
        )
        
        let updatedBy = authViewModel.currentUser?.email ?? "unknown"
        
        print("💾 주간 메뉴 저장 시작")
        print("📅 시작일: \(weeklyInput.startDate)")
        print("🏫 캠퍼스: \(weeklyInput.campus.displayName)")
        print("🍽️ 총 메뉴 수: \(dailyMenus.count)일")
        print("👤 수정자: \(updatedBy)")
        
        try await menuViewModel.supabaseService.saveWeeklyMenu(weeklyInput: weeklyInput, updatedBy: updatedBy)
        
        await MainActor.run {
            print("✅ 주간 메뉴 저장 성공")
            isSaving = false
            
            // 현재 날짜의 메뉴 새로고침
            menuViewModel.loadMenuForCurrentDate()
            
            // 성공 메시지 표시 후 화면 닫기
            alertMessage = "주간 메뉴가 성공적으로 저장되었습니다!"
            showingAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
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

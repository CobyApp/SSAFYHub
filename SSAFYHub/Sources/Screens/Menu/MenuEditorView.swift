import SwiftUI
import ComposableArchitecture
import PhotosUI
import SharedModels

struct MenuEditorView: View {
    let store: StoreOf<MenuEditorFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var saveCompletedTrigger = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                VStack(spacing: 0) {
                    // 커스텀 헤더
                    customHeader(viewStore)
                    
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            // 날짜 선택 헤더
                            dateSelectionHeader(viewStore)
                            
                            // OCR 버튼 (주간 모드에서만 표시)
                            ocrButtonsView(viewStore)
                            
                            // 주간 메뉴 입력 섹션
                            weeklyMenuSection(viewStore)
                            
                            // 저장 버튼
                            saveButtonView(viewStore)
                        }
                        .padding(AppSpacing.lg)
                    }
                    .background(AppColors.backgroundPrimary)
                    .onTapGesture {
                        // 키보드가 떠있을 때 다른 곳을 터치하면 키보드 닫기
                        hideKeyboard()
                    }
                }
                
                // 로딩 오버레이 (사진 분석 중, 저장 중, 또는 데이터 로딩 중일 때 표시)
                if viewStore.isAnalyzingImage || viewStore.isSaving || viewStore.isLoading {
                    loadingOverlay(viewStore)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
                // 전달받은 날짜로 주 시작일 초기화
                let calendar = Calendar.current
                let targetDate = viewStore.currentDate // 현재 선택된 날짜 사용
                
                // 해당 날짜가 포함된 주의 월요일을 찾기
                let weekday = calendar.component(.weekday, from: targetDate)
                let daysFromMonday = weekday == 1 ? 6 : weekday - 2 // 일요일이면 6일 전, 월요일이면 0일 전
                
                if let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: targetDate) {
                    viewStore.send(.weekStartChanged(monday))
                    print("📅 주 시작일 설정: \(monday.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .onChange(of: viewStore.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
            }
            .alert("저장 실패", isPresented: .constant(viewStore.errorMessage != nil)) {
                Button("확인") {
                    viewStore.send(.clearError)
                }
            } message: {
                if let errorMessage = viewStore.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("메뉴 덮어쓰기", isPresented: .constant(false)) {
                Button("저장", role: .destructive) {
                    viewStore.send(.saveWeeklyMenu)
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("기존 메뉴가 있을 경우 데이터가 덮어쓰기 됩니다.\n저장하시겠습니까?")
            }
            .fullScreenCover(isPresented: .constant(viewStore.showImagePicker && viewStore.imagePickerSourceType == .camera)) {
                CameraView(selectedImage: $selectedImage, onImageSelected: { image in
                    if let image = image {
                        processSelectedImage(image, viewStore)
                    }
                    selectedImage = nil
                    viewStore.send(.hideImagePicker)
                })
                .ignoresSafeArea()
            }
            .sheet(isPresented: .constant(viewStore.showImagePicker && viewStore.imagePickerSourceType == .photoLibrary)) {
                ImagePicker(selectedImage: $selectedImage, onImageSelected: { image in
                    if let image = image {
                        processSelectedImage(image, viewStore)
                    }
                    selectedImage = nil
                    viewStore.send(.hideImagePicker)
                })
            }
        }
    }
    
    // MARK: - Custom Header
    @ViewBuilder
    private func customHeader(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: 0) {
            // 상단 뒤로가기 버튼과 제목
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(22)
                }
                
                Spacer()
                
                Text("주간 메뉴 등록")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // 오른쪽 여백을 위한 투명 버튼
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.clear)
                        .frame(width: 44, height: 44)
                }
                .disabled(true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Date Selection Header
    @ViewBuilder
    private func dateSelectionHeader(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button(action: {
                    let calendar = Calendar.current
                    if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: viewStore.selectedWeekStart) {
                        viewStore.send(.weekStartChanged(newWeekStart))
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppCornerRadius.pill)
                }
                
                Spacer()
                
                Text(weekRangeText(from: viewStore.selectedWeekStart))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    let calendar = Calendar.current
                    if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: viewStore.selectedWeekStart) {
                        viewStore.send(.weekStartChanged(newWeekStart))
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppCornerRadius.pill)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppCornerRadius.large)
        .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
    }
    
    // 주 범위 텍스트 (월~금)
    private func weekRangeText(from startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        
        let calendar = Calendar.current
        let monday = startDate
        let friday = calendar.date(byAdding: .day, value: 4, to: startDate) ?? startDate
        
        return "\(formatter.string(from: monday)) ~ \(formatter.string(from: friday))"
    }
    
    // MARK: - OCR Buttons View
    @ViewBuilder
    private func ocrButtonsView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                Text("AI 메뉴 인식")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("주간 식단표 사진을 촬영하거나 선택하면\nAI가 자동으로 메뉴를 인식합니다")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            HStack(spacing: AppSpacing.lg) {
                // 카메라 버튼
                Button(action: { 
                    viewStore.send(.showImagePicker(.camera))
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("카메라")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primary)
                    .cornerRadius(16)
                    .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
                }
                
                // 앨범 버튼
                Button(action: { 
                    viewStore.send(.showImagePicker(.photoLibrary))
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("앨범")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary, lineWidth: 1.5)
                    )
                    .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppCornerRadius.large)
        .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
        .alert("권한 필요", isPresented: .constant(false)) {
            Button("설정으로 이동") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("카메라 또는 앨범 접근 권한이 필요합니다. 설정에서 허용해주세요.")
        }
    }
    
    // MARK: - Weekly Menu Section
    @ViewBuilder
    private func weeklyMenuSection(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // 주간 메뉴 입력 폼
            ForEach(0..<5, id: \.self) { dayIndex in
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // 날짜 헤더
                    HStack {
                        let calendar = Calendar.current
                        let date = calendar.date(byAdding: .day, value: dayIndex, to: viewStore.selectedWeekStart) ?? Date()
                        Text("\(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        // 해당 날짜의 메뉴 개수 표시
                        let dayItems = viewStore.weeklyMenuItems[dayIndex]
                        let totalItems = dayItems.filter { !$0.text.isEmpty }.count
                        if totalItems > 0 {
                            Text("\(totalItems)개")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // A타입 메뉴
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("A타입")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewStore.send(.addMenuItem(dayIndex: dayIndex, mealType: .a))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 18))
                            }
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            let aItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .a }
                            ForEach(aItems.indices, id: \.self) { itemIndex in
                                HStack(spacing: 8) {
                                    TextField("메뉴를 입력하세요", text: .init(
                                        get: { aItems[itemIndex].text },
                                        set: { newValue in
                                            viewStore.send(.itemChanged(dayIndex: dayIndex, itemId: aItems[itemIndex].id, text: newValue))
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    
                                    Button(action: {
                                        viewStore.send(.removeMenuItem(dayIndex: dayIndex, itemId: aItems[itemIndex].id))
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(AppColors.error)
                                            .font(.system(size: 16))
                                    }
                                    .disabled(aItems.count <= 1)
                                }
                            }
                        }
                    }
                    
                    // B타입 메뉴
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("B타입")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                viewStore.send(.addMenuItem(dayIndex: dayIndex, mealType: .b))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primary)
                                    .font(.system(size: 18))
                            }
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            let bItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .b }
                            ForEach(bItems.indices, id: \.self) { itemIndex in
                                HStack(spacing: 8) {
                                    TextField("메뉴를 입력하세요", text: .init(
                                        get: { bItems[itemIndex].text },
                                        set: { newValue in
                                            viewStore.send(.itemChanged(dayIndex: dayIndex, itemId: bItems[itemIndex].id, text: newValue))
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    
                                    Button(action: {
                                        viewStore.send(.removeMenuItem(dayIndex: dayIndex, itemId: bItems[itemIndex].id))
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(AppColors.error)
                                            .font(.system(size: 16))
                                    }
                                    .disabled(bItems.count <= 1)
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppCornerRadius.medium)
                .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
            }
        }
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private func loadingOverlay(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // 로딩 컨텐츠
            VStack(spacing: AppSpacing.xl) {
                // 로딩 스피너
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.primary)
                
                VStack(spacing: AppSpacing.md) {
                    if viewStore.isAnalyzingImage {
                        Text("AI가 메뉴를 분석하고 있습니다...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("잠시만 기다려주세요")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if viewStore.isSaving {
                        Text("메뉴를 저장하고 있습니다...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("잠시만 기다려주세요")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if viewStore.isLoading {
                        Text("기존 메뉴를 불러오고 있습니다...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("잠시만 기다려주세요")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 진행 상태 표시 (AI 분석 중일 때만)
                if viewStore.isAnalyzingImage {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(AppColors.primary.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == 0 ? 1.2 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: viewStore.isAnalyzingImage
                                )
                        }
                    }
                }
            }
            .padding(AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
            )
        }
        .allowsHitTesting(true) // 터치 이벤트 차단
    }
    
    // MARK: - Save Button View
    @ViewBuilder
    private func saveButtonView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        Button(action: {
            viewStore.send(.saveWeeklyMenu)
        }) {
            HStack(spacing: 12) {
                if viewStore.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                }
                Text(viewStore.isSaving ? "저장 중..." : "저장")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(hasValidMenuData(viewStore) ? AppColors.primary : AppColors.textTertiary)
            .cornerRadius(16)
            .shadow(
                color: hasValidMenuData(viewStore) ? AppColors.primary.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!hasValidMenuData(viewStore) || viewStore.isSaving)
        .scaleEffect(hasValidMenuData(viewStore) ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.2), value: hasValidMenuData(viewStore))
    }
    
    // MARK: - Menu Validation
    private func hasValidMenuData(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> Bool {
        // 주간 모드: 최소 하나의 메뉴라도 실제 내용이 입력되어야 함
        return viewStore.weeklyMenuItems.enumerated().contains { index, items in
            let hasValidItems = items.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return hasValidItems
        }
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func processSelectedImage(_ image: UIImage, _ viewStore: ViewStoreOf<MenuEditorFeature>) {
        let imageData = image.jpegData(compressionQuality: 0.8)
        if let data = imageData {
            viewStore.send(.imageSelected(data))
        }
    }
}

#Preview {
    MenuEditorView(
        store: Store(initialState: MenuEditorFeature.State()) {
            MenuEditorFeature()
        }
    )
}
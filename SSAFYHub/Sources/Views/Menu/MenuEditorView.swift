import SwiftUI
import ComposableArchitecture
import PhotosUI
import SharedModels

struct MenuEditorView: View {
    let store: StoreOf<MenuEditorFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var saveCompletedTrigger = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(spacing: 0) {
                    // 헤더
                    headerView(viewStore)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // 주간 네비게이션
                            weekNavigationView(viewStore)
                            
                            // AI 메뉴 인식 버튼들
                            aiMenuRecognitionView(viewStore)
                            
                            // 메뉴 입력 폼
                            menuInputView(viewStore)
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 저장 버튼
                    saveButtonView(viewStore)
                }
                .background(AppColors.backgroundPrimary)
                .navigationBarHidden(true)
                .onAppear {
                    viewStore.send(.onAppear)
                    // 주 시작일을 월요일로 자동 설정
                    let monday = getMondayOfCurrentWeek()
                    if monday != viewStore.selectedWeekStart {
                        viewStore.send(.weekStartChanged(monday))
                    }
                }
                .onChange(of: viewStore.shouldDismiss) { _, shouldDismiss in
                    // 저장이 완료되면 팝업을 닫음
                    if shouldDismiss {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
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
            .sheet(isPresented: .constant(viewStore.showImagePicker)) {
                ImagePickerRepresentable(
                    sourceType: viewStore.imagePickerSourceType == .camera ? .camera : .photoLibrary,
                    onImagePicked: { image in
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            viewStore.send(.analyzeImageData(imageData))
                        } else {
                            viewStore.send(.imageAnalysisFailed("이미지를 처리할 수 없습니다"))
                        }
                    },
                    onCancel: {
                        viewStore.send(.hideImagePicker)
                    }
                )
            }
        }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private func headerView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        HStack {
            Button("취소") {
                dismiss()
            }
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text("메뉴 등록")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if viewStore.isSaving {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Color.clear
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surfacePrimary)
    }
    
    // MARK: - Week Navigation View
    @ViewBuilder
    private func weekNavigationView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        HStack {
            Button(action: {
                let previousWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: viewStore.selectedWeekStart) ?? Date()
                viewStore.send(.weekStartChanged(previousWeek))
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(22)
            }
            
            Spacer()
            
            Text(weekRangeString(from: viewStore.selectedWeekStart))
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {
                let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: viewStore.selectedWeekStart) ?? Date()
                viewStore.send(.weekStartChanged(nextWeek))
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(22)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Menu Input View
    @ViewBuilder
    private func menuInputView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: 16) {
            // 1일차 (월요일)
            let date1 = Calendar.current.date(byAdding: .day, value: 0, to: viewStore.selectedWeekStart) ?? Date()
            menuDayView(viewStore: viewStore, dayIndex: 0, date: date1)
            
            // 2일차 (화요일)
            let date2 = Calendar.current.date(byAdding: .day, value: 1, to: viewStore.selectedWeekStart) ?? Date()
            menuDayView(viewStore: viewStore, dayIndex: 1, date: date2)
            
            // 3일차 (수요일)
            let date3 = Calendar.current.date(byAdding: .day, value: 2, to: viewStore.selectedWeekStart) ?? Date()
            menuDayView(viewStore: viewStore, dayIndex: 2, date: date3)
            
            // 4일차 (목요일)
            let date4 = Calendar.current.date(byAdding: .day, value: 3, to: viewStore.selectedWeekStart) ?? Date()
            menuDayView(viewStore: viewStore, dayIndex: 3, date: date4)
            
            // 5일차 (금요일)
            let date5 = Calendar.current.date(byAdding: .day, value: 4, to: viewStore.selectedWeekStart) ?? Date()
            menuDayView(viewStore: viewStore, dayIndex: 4, date: date5)
        }
    }
    
    @ViewBuilder
    private func menuDayView(viewStore: ViewStoreOf<MenuEditorFeature>, dayIndex: Int, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayString(from: date))
                    .font(AppTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            // A타입 메뉴
            VStack(alignment: .leading, spacing: 8) {
                Text("A타입")
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.accentPrimary)
                
                TextField("A타입 메뉴를 입력하세요", text: .init(
                    get: { 
                        let aItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .a }
                        return aItems.first?.text ?? ""
                    },
                    set: { newValue in
                        let aItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .a }
                        if let firstAItem = aItems.first {
                            viewStore.send(.itemChanged(dayIndex: dayIndex, itemId: firstAItem.id, text: newValue))
                        }
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // B타입 메뉴
            VStack(alignment: .leading, spacing: 8) {
                Text("B타입")
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.accentSecondary)
                
                TextField("B타입 메뉴를 입력하세요", text: .init(
                    get: { 
                        let bItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .b }
                        return bItems.first?.text ?? ""
                    },
                    set: { newValue in
                        let bItems = viewStore.weeklyMenuItems[dayIndex].filter { $0.mealType == .b }
                        if let firstBItem = bItems.first {
                            viewStore.send(.itemChanged(dayIndex: dayIndex, itemId: firstBItem.id, text: newValue))
                        }
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(16)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - AI Menu Recognition View
    @ViewBuilder
    private func aiMenuRecognitionView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.accentPrimary)
                
                Text("AI 메뉴 인식")
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if viewStore.isAnalyzingImage {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text("식단표 사진을 촬영하거나 선택하면 AI가 자동으로 메뉴를 인식합니다")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 12) {
                // 카메라 버튼
                Button(action: {
                    viewStore.send(.showImagePicker(.camera))
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("사진 촬영")
                    }
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accentPrimary)
                    .cornerRadius(8)
                }
                .disabled(viewStore.isAnalyzingImage)
                
                // 앨범 버튼
                Button(action: {
                    viewStore.send(.showImagePicker(.photoLibrary))
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("앨범 선택")
                    }
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accentSecondary)
                    .cornerRadius(8)
                }
                .disabled(viewStore.isAnalyzingImage)
            }
        }
        .padding(16)
        .background(AppColors.surfaceSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Save Button View
    @ViewBuilder
    private func saveButtonView(_ viewStore: ViewStoreOf<MenuEditorFeature>) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                viewStore.send(.saveWeeklyMenu)
            }) {
                HStack {
                    if viewStore.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(viewStore.isSaving ? "저장 중..." : "주간 메뉴 저장")
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.accentPrimary)
                .cornerRadius(12)
            }
            .disabled(viewStore.isSaving)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppColors.surfacePrimary)
    }
    
    // MARK: - Helper Methods
    private func weekRangeString(from startDate: Date) -> String {
        let endDate = Calendar.current.date(byAdding: .day, value: 4, to: startDate) ?? startDate
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }
    
    // 현재 주의 월요일을 반환
    private func getMondayOfCurrentWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // 오늘 날짜의 주차를 구함
        let weekOfYear = calendar.component(.weekOfYear, from: today)
        let year = calendar.component(.year, from: today)
        
        // 해당 주의 월요일을 구함
        let firstWeekday = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        // 월요일이 아닌 경우 이전 월요일로 조정
        let weekday = calendar.component(.weekday, from: firstWeekday)
        let daysToSubtract = weekday - 2 // 월요일은 2, 일요일은 1
        
        if daysToSubtract > 0 {
            return calendar.date(byAdding: .day, value: -daysToSubtract, to: firstWeekday) ?? today
        }
        
        return firstWeekday
    }
}

// MARK: - ImagePickerRepresentable
struct ImagePickerRepresentable: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerRepresentable
        
        init(_ parent: ImagePickerRepresentable) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
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
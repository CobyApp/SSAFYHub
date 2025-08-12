import SwiftUI
import PhotosUI

struct MenuEditorView: View {
    @ObservedObject var menuViewModel: MenuViewModel
    let date: Date
    
    @State private var itemsA: [String] = []
    @State private var itemsB: [String] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingImage = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private let ocrService = OCRService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Date Header
                dateHeaderView
                
                // OCR Buttons
                ocrButtonsView
                
                // Menu Input Forms
                menuInputFormsView
                
                Spacer()
                
                // Save Button
                saveButtonView
            }
            .padding()
            .navigationTitle("메뉴 편집")
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
            .onChange(of: selectedImage) { image in
                if let image = image {
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
    
    // MARK: - Date Header View
    private var dateHeaderView: some View {
        VStack(spacing: 8) {
            Text(date, style: .date)
                .font(.title2)
                .fontWeight(.semibold)
            
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
    
    // MARK: - Menu Input Forms View
    private var menuInputFormsView: some View {
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
    
    // MARK: - Save Button View
    private var saveButtonView: some View {
        Button(action: saveMenu) {
            HStack {
                if menuViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("저장")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(menuViewModel.isLoading || (itemsA.isEmpty && itemsB.isEmpty))
    }
    
    // MARK: - Helper Methods
    private func loadExistingMenu() {
        if let menu = menuViewModel.currentMenu {
            itemsA = menu.itemsA
            itemsB = menu.itemsB
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessingImage = true
        
        Task {
            do {
                let text = try await ocrService.extractText(from: image)
                let parsedMenu = ocrService.parseMenuFromText(text)
                
                await MainActor.run {
                    itemsA = parsedMenu.itemsA
                    itemsB = parsedMenu.itemsB
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
        Task {
            await menuViewModel.saveMenu(itemsA: itemsA, itemsB: itemsB)
            
            if menuViewModel.errorMessage == nil {
                dismiss()
            } else {
                alertMessage = menuViewModel.errorMessage ?? "저장에 실패했습니다."
                showingAlert = true
            }
        }
    }
}

// MARK: - Menu Type Input View
struct MenuTypeInputView: View {
    let title: String
    @Binding var items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
                
                Button(action: { items.append("") }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                }
            }
            
            if items.isEmpty {
                Text("메뉴를 입력해주세요")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(items.indices, id: \.self) { index in
                        HStack {
                            TextField("메뉴 항목", text: $items[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: { items.remove(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    MenuEditorView(
        menuViewModel: MenuViewModel(),
        date: Date()
    )
}

import SwiftUI

// MARK: - Campus Picker View
struct CampusPickerView: View {
    @Binding var selectedCampus: Campus
    let onCampusSelected: (Campus) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(Campus.allCases, id: \.self) { campus in
                Button(action: {
                    selectedCampus = campus
                    onCampusSelected(campus)
                    dismiss()
                }) {
                    HStack {
                        Text(campus.displayName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if campus == selectedCampus {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("캠퍼스 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CampusPickerView(
        selectedCampus: .constant(.seoul)
    ) { campus in
        print("Selected campus: \(campus.displayName)")
    }
}

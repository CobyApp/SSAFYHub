import SwiftUI

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

#Preview {
    MenuTypeInputView(
        title: "A타입",
        items: .constant(["백미밥", "미역국"]),
        color: .blue
    )
    .padding()
}

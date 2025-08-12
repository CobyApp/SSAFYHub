import SwiftUI

// MARK: - Menu Display View
struct MenuDisplayView: View {
    let menu: Menu
    
    var body: some View {
        VStack(spacing: 16) {
            // A Type Menu
            MenuTypeView(
                title: "A타입",
                items: menu.itemsA,
                color: .blue
            )
            
            // B Type Menu
            MenuTypeView(
                title: "B타입",
                items: menu.itemsB,
                color: .green
            )
            
            // Update Info
            HStack {
                Text("최종 수정: \(menu.updatedAt, style: .relative) 전")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("v\(menu.revision)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Menu Type View
struct MenuTypeView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal)
            
            if items.isEmpty {
                Text("메뉴 정보가 없습니다")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text("•")
                                .foregroundColor(color)
                            Text(item)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Empty Menu View
struct EmptyMenuView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("오늘 메뉴가 등록되지 않았습니다")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("아래 버튼을 눌러 메뉴를 등록해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

#Preview {
    VStack {
        MenuDisplayView(menu: Menu(
            id: "1",
            date: Date(),
            campus: .seoul,
            itemsA: ["백미밥", "미역국", "제육볶음"],
            itemsB: ["잡곡밥", "된장국", "닭볶음"],
            updatedAt: Date(),
            updatedBy: "user1",
            revision: 1
        ))
        
        EmptyMenuView()
    }
}

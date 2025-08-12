import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingCampusPicker = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var selectedCampus: Campus
    
    @Environment(\.dismiss) private var dismiss
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self._selectedCampus = State(initialValue: authViewModel.currentUser?.campus ?? .seoul)
    }
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section("사용자 정보") {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.email ?? "이메일 없음")
                                    .font(.headline)
                                Text("가입일: \(user.createdAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Campus Section
                Section("캠퍼스 설정") {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("현재 캠퍼스")
                                .font(.subheadline)
                            Text(selectedCampus.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button("변경") {
                            showingCampusPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // Account Actions Section
                Section("계정 관리") {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.orange)
                            Text("로그아웃")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: { showingDeleteAccountAlert = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .foregroundColor(.red)
                            Text("회원 탈퇴")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Info Section
                Section("앱 정보") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("개발자")
                        Spacer()
                        Text("SSAFY")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCampusPicker) {
                CampusPickerView(selectedCampus: $selectedCampus) { campus in
                    Task {
                        await authViewModel.updateUserCampus(campus)
                        selectedCampus = campus
                    }
                }
            }
            .alert("로그아웃", isPresented: $showingLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("정말 로그아웃 하시겠습니까?")
            }
            .alert("회원 탈퇴", isPresented: $showingDeleteAccountAlert) {
                Button("취소", role: .cancel) { }
                Button("탈퇴", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("정말 회원 탈퇴를 하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
}

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
    SettingsView(authViewModel: AuthViewModel())
}

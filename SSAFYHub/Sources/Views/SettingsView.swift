import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCampus: Campus
    @State private var showCampusPicker = false
    @State private var showDeleteConfirmation = false
    
    init() {
        self._selectedCampus = State(initialValue: .seoul)
    }
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section("사용자 정보") {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.email)
                                .font(.headline)
                            Text("가입일: \(user.createdAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Campus Section
                Section("캠퍼스 설정") {
                    HStack {
                        Text("현재 캠퍼스")
                        Spacer()
                        Button(action: { showCampusPicker = true }) {
                            HStack {
                                Text(selectedCampus.displayName)
                                    .foregroundColor(.blue)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Account Actions Section
                Section("계정 관리") {
                    Button(action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("로그아웃")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("계정 삭제")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Info Section
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("SSAFY")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        // Dismiss
                    }
                }
            }
            .sheet(isPresented: $showCampusPicker) {
                CampusPickerView(
                    selectedCampus: $selectedCampus,
                    onCampusSelected: { campus in
                        Task {
                            if let user = authViewModel.currentUser {
                                await authViewModel.updateUserCampus(campus)
                            }
                        }
                    }
                )
            }
            .alert("계정 삭제", isPresented: $showDeleteConfirmation) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                selectedCampus = user.campus
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}


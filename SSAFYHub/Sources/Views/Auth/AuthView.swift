import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showCampusSelection = false
    @State private var selectedCampus: Campus = .seoul
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo & Title
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("SSAFYHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("캠퍼스별 점심 메뉴를 확인하고 공유하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Sign In Button
                VStack(spacing: 16) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    
                    // 임시 테스트 로그인 버튼 (Apple 로그인 문제 해결 후 제거)
                    Button(action: {
                        Task {
                            await authViewModel.signInWithApple()
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                            Text("테스트 로그인 (Apple 로그인 문제 해결 후 제거)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                    .padding(.horizontal, 40)
                    
                    // Or Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        
                        Text("또는")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal, 40)
                    
                    // Guest Sign In Button
                    Button(action: {
                        // 게스트 로그인 (캠퍼스 선택으로 이동)
                        showCampusSelection = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("게스트로 시작하기")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Footer
                Text("SSAFY World Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showCampusSelection) {
                CampusSelectionView(selectedCampus: $selectedCampus) {
                    // 게스트 사용자로 메인 화면으로 이동
                    // TODO: 게스트 사용자 처리
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("로그인 오류", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("확인") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Apple Sign In Handler
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authViewModel.errorMessage = "Apple ID 인증 정보를 가져올 수 없습니다."
                return
            }
            
            Task {
                await performAppleSignIn(credential: appleIDCredential)
            }
            
        case .failure(let error):
            authViewModel.errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    private func performAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        do {
            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                await MainActor.run {
                    authViewModel.errorMessage = "Apple ID 토큰을 가져올 수 없습니다."
                }
                return
            }
            
            let user = try await authViewModel.supabaseService.authenticateWithApple(
                identityToken: identityToken
            )
            
            // 로그인 성공 시 캠퍼스 선택 화면으로 이동
            await MainActor.run {
                selectedCampus = user.campus
                showCampusSelection = true
            }
            
        } catch {
            await MainActor.run {
                authViewModel.errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Campus Selection View
struct CampusSelectionView: View {
    @Binding var selectedCampus: Campus
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "building.2")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("캠퍼스를 선택해주세요")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("선택한 캠퍼스의 점심 메뉴를 확인할 수 있습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Campus Options
                VStack(spacing: 16) {
                    ForEach(Campus.allCases, id: \.self) { campus in
                        CampusOptionRow(
                            campus: campus,
                            isSelected: selectedCampus == campus
                        ) {
                            selectedCampus = campus
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    onComplete()
                    dismiss()
                }) {
                    Text("계속하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("캠퍼스 선택")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Campus Option Row
struct CampusOptionRow: View {
    let campus: Campus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campus.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(campus.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AuthView()
}

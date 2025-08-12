import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
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
                
                // Sign In Options
                VStack(spacing: 20) {
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
                    .disabled(authViewModel.isLoading)
                    
                    // Guest Mode Button
                    Button(action: {
                        print("🎯 게스트 모드 선택됨")
                        appCoordinator.navigateToCampusSelection()
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
                    .disabled(authViewModel.isLoading)
                    
                    // Loading Indicator
                    if authViewModel.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("로그인 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Footer
                Text("SSAFY World Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarHidden(true)
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
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
            print("🍎 Apple 로그인 실패: \(error)")
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    print("🍎 사용자가 Apple 로그인 취소")
                    // 사용자가 취소한 경우 에러 메시지 표시하지 않음
                case .failed:
                    authViewModel.errorMessage = "Apple 로그인에 실패했습니다."
                case .invalidResponse:
                    authViewModel.errorMessage = "Apple 로그인 응답이 유효하지 않습니다."
                case .notHandled:
                    authViewModel.errorMessage = "Apple 로그인이 처리되지 않았습니다."
                case .unknown:
                    authViewModel.errorMessage = "Apple 로그인 중 알 수 없는 오류가 발생했습니다."
                @unknown default:
                    authViewModel.errorMessage = "Apple 로그인 중 오류가 발생했습니다."
                }
            } else {
                authViewModel.errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            }
        }
    }
    
    private func performAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        print("🍎 Apple 로그인 성공, Supabase 인증 시작")
        
        // Apple 로그인 성공 시 새로운 메서드 사용
        await authViewModel.signInWithAppleAndNavigate()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
}

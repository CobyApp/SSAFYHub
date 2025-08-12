import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var selectedCampus: Campus = .seoul
    @State private var isAppleSignInInProgress = false  // Apple 로그인 진행 상태 추가
    
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
                    .disabled(authViewModel.isLoading || isAppleSignInInProgress)  // 중복 실행 방지
                    
                    // Guest Mode Button
                    Button(action: {
                        print("🎯 게스트 모드 선택됨")
                        handleGuestMode()
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
                    .disabled(authViewModel.isLoading || isAppleSignInInProgress)  // 중복 실행 방지
                    
                    // Loading Indicator
                    if authViewModel.isLoading || isAppleSignInInProgress {
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
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        // 중복 실행 방지
        guard !isAppleSignInInProgress else {
            print("⚠️ Apple 로그인이 이미 진행 중입니다")
            return
        }
        
        isAppleSignInInProgress = true  // 로그인 진행 상태 설정
        
        switch result {
        case .success(let authorization):
            print("🍎 Apple 로그인 성공, Supabase 인증 시작")
            Task {
                do {
                    await authViewModel.signInWithAppleAndNavigate()
                    
                    // 로그인 성공 후 상태 초기화
                    await MainActor.run {
                        isAppleSignInInProgress = false
                        print("✅ Apple 로그인 완료, 상태 초기화됨")
                    }
                } catch {
                    // 로그인 실패 시 상태 초기화
                    await MainActor.run {
                        isAppleSignInInProgress = false
                        print("❌ Apple 로그인 실패, 상태 초기화됨")
                    }
                }
            }
        case .failure(let error):
            print("❌ Apple 로그인 실패: \(error)")
            
            // 로그인 실패 시 상태 초기화
            isAppleSignInInProgress = false
            
            // 사용자 친화적인 에러 메시지 표시
            let errorMessage: String
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    errorMessage = "Apple 로그인이 취소되었습니다."
                case .failed:
                    errorMessage = "Apple 로그인에 실패했습니다. 다시 시도해주세요."
                case .invalidResponse:
                    errorMessage = "Apple 로그인 응답이 유효하지 않습니다. 다시 시도해주세요."
                case .notHandled:
                    errorMessage = "Apple 로그인이 처리되지 않았습니다. 다시 시도해주세요."
                case .unknown:
                    errorMessage = "Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요."
                @unknown default:
                    errorMessage = "Apple 로그인 중 오류가 발생했습니다. 다시 시도해주세요."
                }
            } else {
                errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            }
            
            authViewModel.errorMessage = errorMessage
        }
    }
    
    private func handleGuestMode() {
        print("🎯 게스트 모드 처리 시작")
        
        // 게스트 모드 시작 - 캠퍼스 선택 화면으로 이동
        // 실제 게스트 사용자 생성은 캠퍼스 선택 후에 이루어짐
        appCoordinator.navigateToCampusSelection()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
}

import SwiftUI
import AuthenticationServices
import SharedModels

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        ZStack {
            // 전체 배경을 로딩 화면과 같은 색상으로 설정
            Color(red: 1/255, green: 158/255, blue: 235/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                
                // 로고 및 메인 메시지
                VStack(spacing: AppSpacing.xl) {
                    // 로고
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                    
                    // 메인 메시지
                    Text("식단 관리부터 다양한 서비스까지\n한 곳에서 편리하게")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, AppSpacing.xl)
                
                Spacer()
                
                // 로그인 버튼들
                VStack(spacing: AppSpacing.lg) {
                    // Apple Sign-In 버튼
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            // nonce 설정 추가
                            let rawNonce = AppleSignInService.shared.generateNonce()
                            request.nonce = AppleSignInService.shared.sha256(rawNonce)
                            print("🍎 Apple Sign-In 요청 - nonce 설정됨")
                        },
                        onCompletion: { result in
                            // 중복 호출 방지
                            guard !authViewModel.isAppleSignInInProgress else {
                                print("⚠️ Apple Sign-In이 이미 진행 중입니다")
                                return
                            }
                            
                            Task {
                                await handleAppleSignIn(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .disabled(authViewModel.isAppleSignInInProgress)
                    .opacity(authViewModel.isAppleSignInInProgress ? 0.6 : 1.0)
                    .allowsHitTesting(!authViewModel.isAppleSignInInProgress)
                    
                    // 게스트 모드 버튼
                    Button(action: {
                        Task {
                            await authViewModel.signInAsGuest(campus: .daejeon)
                        }
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("게스트로 시작하기")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white.opacity(0.2))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // 하단 정보
                VStack(spacing: AppSpacing.sm) {
                    Text("2025 Coby")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .alert("로그인 실패", isPresented: $authViewModel.showError) {
            Button("확인") { }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            } else {
                Text("알 수 없는 오류가 발생했습니다.")
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        // 중복 호출 방지
        guard !authViewModel.isAppleSignInInProgress else {
            print("⚠️ Apple Sign-In이 이미 진행 중입니다")
            return
        }
        
        do {
            print("🍎 Apple Sign-In 결과 처리 시작")
            
            // Apple Sign-In 결과를 처리하여 Identity Token과 nonce 획득
            let result = try await AppleSignInService.shared.handleAppleSignInCompletion(result)
            print("🍎 Apple Sign-In 성공, Identity Token과 nonce 획득")
            
            // Supabase 인증 진행 (nonce 포함)
            try await authViewModel.completeAppleSignIn(with: result.identityToken, nonce: result.nonce)
            
        } catch {
            print("❌ Apple Sign-In 실패: \(error)")
            
            // 중복 호출 에러는 사용자에게 표시하지 않음
            if let nsError = error as NSError?, nsError.code == -10 {
                print("ℹ️ 중복 호출 에러 - 사용자에게 표시하지 않음")
                return
            }
            
            // 다른 에러는 AuthViewModel에서 처리되므로 여기서는 로그만 출력
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
}

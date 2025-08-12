import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // SSAFY 로고 및 메인 메시지
                VStack(spacing: 24) {
                    // SSAFY 로고
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundStyle(AppColors.primaryGradient)
                        }
                        
                        Text("SSAFYHub")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    // 메인 메시지
                    VStack(spacing: 12) {
                        Text("SSAFY 학생들을 위한\n종합 허브")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Text("식단 관리부터 다양한 서비스까지\n한 곳에서 편리하게")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // 로그인 버튼들
                VStack(spacing: 16) {
                    // Apple Sign-In 버튼
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                await handleAppleSignIn(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .disabled(authViewModel.isAppleSignInInProgress)
                    .opacity(authViewModel.isAppleSignInInProgress ? 0.6 : 1.0)
                    
                    // 게스트 모드 버튼
                    Button(action: {
                        appCoordinator.navigateToCampusSelection()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("게스트로 시작하기")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // 하단 정보
                VStack(spacing: 8) {
                    Text("2025 Coby")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.bottom, 32)
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
        do {
            try await authViewModel.signInWithAppleAndNavigate()
        } catch {
            print("❌ Apple Sign-In 실패: \(error)")
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppCoordinator())
}

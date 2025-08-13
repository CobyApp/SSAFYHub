import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        VStack(spacing: 0) {
            // 상단 여백
            Spacer()
            
            // SSAFY 로고 및 메인 메시지
            VStack(spacing: AppSpacing.xl) {
                // SSAFY 로고
                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text("SSAFYHub")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                // 메인 메시지
                VStack(spacing: AppSpacing.md) {
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
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            // 로그인 버튼들
            VStack(spacing: AppSpacing.lg) {
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
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black) // 테마에 따라 자동 조정
                .frame(height: 56)
                .cornerRadius(16)
                .disabled(authViewModel.isAppleSignInInProgress)
                .opacity(authViewModel.isAppleSignInInProgress ? 0.6 : 1.0)
                
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
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: AppShadow.small.color, radius: AppShadow.small.radius, x: AppShadow.small.x, y: AppShadow.small.y)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            
            Spacer()
            
            // 하단 정보
            VStack(spacing: AppSpacing.sm) {
                Text("2025 Coby")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.backgroundPrimary)
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

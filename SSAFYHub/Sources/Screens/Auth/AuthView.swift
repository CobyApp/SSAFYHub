import SwiftUI
import ComposableArchitecture
import AuthenticationServices
import SharedModels

struct AuthView: View {
    let store: StoreOf<AuthFeature>
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                        Group {
                            if let _ = UIImage(named: "logo") {
                                Image("logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 150)
                            } else {
                                Image(systemName: "fork.knife.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 150)
                                    .foregroundColor(.white)
                            }
                        }
                        
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
                                guard !viewStore.isLoading else {
                                    print("⚠️ Apple Sign-In이 이미 진행 중입니다")
                                    return
                                }
                                
                                Task {
                                    await handleAppleSignIn(result, viewStore)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 56)
                        .cornerRadius(16)
                        .disabled(viewStore.isLoading)
                        .opacity(viewStore.isLoading ? 0.6 : 1.0)
                        .allowsHitTesting(!viewStore.isLoading)
                        
                        // 게스트 모드 버튼
                        Button(action: {
                            viewStore.send(.signInAsGuest)
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
                        .disabled(viewStore.isLoading)
                        .opacity(viewStore.isLoading ? 0.6 : 1.0)
                        .allowsHitTesting(!viewStore.isLoading)
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
                
                // 에러 메시지 표시
                if let errorMessage = viewStore.errorMessage {
                    VStack {
                        Spacer()
                        
                        Text(errorMessage)
                            .font(AppTypography.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    // MARK: - Apple Sign-In Handler
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>, _ viewStore: ViewStoreOf<AuthFeature>) async {
        do {
            let (identityToken, nonce) = try await AppleSignInService.shared.handleAppleSignInCompletion(result)
            print("🍎 Apple Sign-In 성공 - Identity Token 획득")
            
            // Apple 로그인 성공 후 사용자 정보 생성
            // TODO: 실제로는 SupabaseService를 통해 Apple 로그인 처리하고 사용자 정보를 받아와야 함
            let appleUser = AppUser(
                id: UUID().uuidString, // 실제로는 Supabase에서 받은 사용자 ID
                email: "apple.user@example.com", // 실제로는 Apple에서 받은 이메일
                campus: .daejeon, // 기본 캠퍼스
                userType: .authenticated,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // 사용자 인증 완료 액션 전송
            await viewStore.send(.userAuthenticated(appleUser)).finish()
            print("✅ Apple 사용자 인증 완료: \(appleUser.email)")
            
        } catch {
            print("❌ Apple Sign-In 처리 실패: \(error)")
            await viewStore.send(.setError(error.localizedDescription)).finish()
        }
    }
}

#Preview {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        }
    )
}

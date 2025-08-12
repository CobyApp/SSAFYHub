import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Logo & Title
            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("SSAFY 점심식단")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("매일의 점심 메뉴를 한눈에")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Features
            VStack(spacing: 16) {
                FeatureRow(icon: "camera.fill", title: "사진으로 메뉴 인식", description: "OCR 기술로 식단표를 자동으로 읽어옵니다")
                FeatureRow(icon: "calendar", title: "날짜별 메뉴 확인", description: "월~금까지 각 날짜의 메뉴를 쉽게 확인하세요")
                FeatureRow(icon: "building.2.fill", title: "캠퍼스별 메뉴", description: "서울, 대전, 광주, 구미, 부산 캠퍼스 메뉴")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Sign In Button
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await authViewModel.signInWithApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Apple로 계속하기")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading)
                
                if authViewModel.isLoading {
                    ProgressView("로그인 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    AuthView(authViewModel: AuthViewModel())
}

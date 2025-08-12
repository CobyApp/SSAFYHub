# SSAFY 점심식단 앱 (SSAWorld)

SSAFY 캠퍼스의 점심 식단을 확인하고 관리할 수 있는 iOS 앱입니다.

## 🚀 주요 기능

### MVP 기능
- **인증 & 사용자 관리**
  - Apple 로그인
  - 캠퍼스 선택 (서울/대전/광주/구미/부산)
  - 프로필 관리

- **메인 화면**
  - 오늘 점심 식단 표시
  - A타입/B타입 메뉴 구분
  - 날짜별 이동 (월~금)
  - 주 단위 자동 갱신

- **식단 등록 & 수정**
  - 직접 입력 (멀티라인 텍스트)
  - 이미지 OCR 자동 입력
  - 사진 촬영 또는 앨범 선택
  - 수정 이력 관리

- **설정**
  - 캠퍼스 변경
  - 로그아웃
  - 회원 탈퇴

### 기술 스택
- **Frontend**: SwiftUI
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **OCR**: Vision Framework
- **Build Tool**: Tuist

## 📱 앱 구조

```
SSAWorld/
├── Sources/
│   ├── Models/          # 데이터 모델
│   ├── Services/        # 비즈니스 로직
│   ├── ViewModels/      # UI 상태 관리
│   ├── Views/           # UI 컴포넌트
│   └── SSAWorldApp.swift # 앱 진입점
├── Resources/           # 앱 리소스
├── Tests/              # 테스트 코드
├── Tuist/              # 프로젝트 설정
└── database/           # 데이터베이스 스키마
```

## 🛠️ 개발 환경 설정

### 필수 요구사항
- Xcode 15.0+
- iOS 17.0+
- Tuist 4.0+
- Supabase 계정

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd SSAWorld
```

### 2. Tuist 설치 (macOS)
```bash
curl -Ls https://install.tuist.io | bash
```

### 3. 프로젝트 생성
```bash
tuist generate
```

### 4. Supabase 설정
1. [Supabase](https://supabase.com)에서 새 프로젝트 생성
2. `database/schema.sql` 실행하여 데이터베이스 스키마 생성
3. `SSAWorld/Sources/Services/SupabaseService.swift`에서 URL과 API 키 업데이트

```swift
let supabaseURL = "YOUR_SUPABASE_URL"
let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```

### 5. Xcode에서 프로젝트 열기
```bash
open SSAWorld.xcodeproj
```

## 🗄️ 데이터베이스 스키마

### Users 테이블
- `id`: UUID (Primary Key)
- `email`: 사용자 이메일
- `campus_id`: 캠퍼스 ID
- `created_at`: 생성 시간
- `updated_at`: 수정 시간

### Menus 테이블
- `id`: UUID (Primary Key)
- `date`: 날짜
- `campus_id`: 캠퍼스 ID
- `items_a`: A타입 메뉴 배열
- `items_b`: B타입 메뉴 배열
- `updated_at`: 수정 시간
- `updated_by`: 수정자 ID
- `revision`: 수정 버전

## 📱 앱 사용법

### 1. 로그인
- 앱 실행 시 Apple 계정으로 로그인
- 최초 로그인 시 캠퍼스 선택

### 2. 메뉴 확인
- 메인 화면에서 오늘 메뉴 확인
- 좌우 스와이프로 다른 날짜 이동
- "오늘로" 버튼으로 오늘 날짜로 이동

### 3. 메뉴 등록/수정
- "메뉴 추가/수정" 버튼 클릭
- 직접 입력 또는 이미지 OCR 사용
- 사진 촬영 또는 앨범에서 선택
- A타입/B타입 메뉴 입력 후 저장

### 4. 설정
- 우상단 설정 버튼 클릭
- 캠퍼스 변경, 로그아웃, 회원 탈퇴

## 🔧 개발 가이드

### 새로운 기능 추가
1. `Models/`에 데이터 모델 정의
2. `Services/`에 비즈니스 로직 구현
3. `ViewModels/`에 UI 상태 관리
4. `Views/`에 UI 컴포넌트 구현

### 의존성 추가
```bash
# Tuist/Package.swift에 의존성 추가
.package(url: "https://github.com/example/package.git", from: "1.0.0")

# Project.swift에 타겟 의존성 추가
dependencies: [.external(name: "PackageName")]
```

### 빌드 및 테스트
```bash
# 프로젝트 생성
tuist generate

# 테스트 실행
tuist test

# 프로젝트 정리
tuist clean
```

## 🚀 배포

### 1. 버전 업데이트
- `Project.swift`에서 버전 번호 수정
- `SettingsView.swift`에서 앱 버전 표시 업데이트

### 2. 빌드
```bash
tuist build --configuration Release
```

### 3. App Store Connect 업로드
- Xcode에서 Archive 생성
- App Store Connect에 업로드

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해주세요.

---

**SSAFY 점심식단 앱** - 매일의 점심 메뉴를 한눈에! 🍽️

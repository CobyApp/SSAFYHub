# SSAFYHub

SSAFY 캠퍼스별 점심식단을 확인하고 공유할 수 있는 iOS 앱입니다.

## 🚀 주요 기능

- **🍎 Apple 로그인**: 간편한 Apple ID를 통한 인증
- **🏫 캠퍼스별 식단**: 서울, 대전, 광주, 구미, 부산 캠퍼스 지원
- **📅 날짜별 네비게이션**: 이전/다음/오늘 날짜로 메뉴 확인
- **✏️ 메뉴 편집**: 수동으로 메뉴 입력 및 수정
- **📸 OCR 메뉴 인식**: 식단 사진에서 자동으로 메뉴 추출
- **🔄 실시간 동기화**: Supabase를 통한 실시간 데이터 동기화
- **⚙️ 설정 관리**: 캠퍼스 변경, 로그아웃, 계정 삭제

## 🛠️ 기술 스택

- **Frontend**: SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth)
- **Build System**: Tuist
- **Authentication**: Apple Sign In
- **OCR**: Vision Framework
- **Architecture**: MVVM 패턴

## 📱 앱 구조

```
SSAFYHub/
├── Sources/
│   ├── Models/          # 데이터 모델
│   ├── Services/        # 비즈니스 로직
│   ├── ViewModels/      # 뷰 모델
│   ├── Views/           # UI 컴포넌트
│   └── SSAFYHubApp.swift # 앱 진입점
└── database/
    └── schema.sql       # 데이터베이스 스키마
```

## 🚀 시작하기

### 필수 요구사항

- Xcode 15.0+
- iOS 18.0+
- Tuist 4.0+
- Supabase 계정

### 설치 및 실행

1. **프로젝트 클론**
   ```bash
   git clone <repository-url>
   cd SSAFYHub
   ```

2. **Tuist 설치 (필요시)**
   ```bash
   curl -Ls https://install.tuist.io | bash
   ```

3. **프로젝트 생성**
   ```bash
   tuist generate
   ```

4. **Xcode에서 열기**
   ```bash
   open SSAFYHub.xcworkspace
   ```

5. **빌드 및 실행**
   - iPhone 시뮬레이터 선택
   - Run 버튼 클릭

## 🔧 설정

### Supabase 설정

1. Supabase 프로젝트 생성
2. `database/schema.sql` 실행하여 테이블 생성
3. `SSAFYHub/Sources/Services/SupabaseService.swift`에서 URL과 API 키 설정

### Apple Sign In 설정

1. Apple Developer 계정에서 App ID 설정
2. Signing & Capabilities에서 Apple Sign In 활성화
3. Bundle ID를 `com.coby.ssafyhub`로 설정

## 📊 데이터베이스 스키마

### Users 테이블
- 사용자 정보 및 캠퍼스 설정

### Menus 테이블
- 날짜별 캠퍼스별 식단 정보
- A타입/B타입 메뉴 구분
- 덮어씌우기 방식으로 메뉴 관리

## 🎯 주요 특징

### 덮어씌우기 시스템
- 같은 날짜 + 같은 캠퍼스 = 하나의 메뉴만 존재
- 새로운 메뉴 등록 시 기존 것을 자동으로 덮어씌움
- 누구나 수정/등록 가능

### 실시간 동기화
- Supabase를 통한 실시간 데이터 업데이트
- 모든 사용자가 동일한 식단 정보 공유

### OCR 메뉴 인식
- Vision Framework를 사용한 텍스트 인식
- 식단 사진에서 자동으로 메뉴 추출
- A타입/B타입 자동 구분

## 🔒 보안

- Row Level Security (RLS) 적용
- 사용자별 데이터 접근 제어
- Apple ID를 통한 안전한 인증

## 📝 라이선스

이 프로젝트는 SSAFY 교육용으로 제작되었습니다.

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해 주세요.

---

**SSAFYHub** - SSAFY 캠퍼스별 점심식단 앱 🍽️

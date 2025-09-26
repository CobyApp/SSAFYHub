# SSAFYHub

**버전**: 1.0.5  
**최종 업데이트**: 2025년 1월

SSAFY 학생들을 위한 종합 허브 앱으로, 캠퍼스 식단 정보를 제공하고 관리할 수 있는 iOS 앱입니다.

## 📱 스크린샷

> 🎨 스크린샷은 곧 추가될 예정입니다.

## 🚀 주요 기능

- **Apple Sign-In**: 안전한 로그인 시스템
- **게스트 모드**: 제한된 기능으로 체험 가능
- **메뉴 관리**: 단일일/주간 메뉴 등록 및 편집
- **AI 메뉴 인식**: OpenAI GPT-4o-mini API를 사용한 이미지 기반 메뉴 자동 추출
- **캠퍼스별 관리**: 서울, 대전, 광주, 구미, 부산 캠퍼스 지원 (현재 대전캠퍼스만 활성화)
- **다크모드 지원**: 라이트/다크/시스템 테마 자동 지원
- **위젯 지원**: iOS 위젯으로 오늘의 메뉴 확인

## 🏗️ 프로젝트 구조

```
SSAFYHub/
├── 📁 Configuration/              # 설정 파일
│   └── env.example               # 환경 변수 예시
├── 📁 Documentation/             # 문서
│   ├── database/                 # 데이터베이스 스키마
│   ├── README.md                 # 상세 문서
│   └── WIDGET_README.md          # 위젯 문서
├── 📁 Scripts/                   # 빌드 스크립트
├── 📁 SharedModels/              # 공유 모델
│   └── Sources/
│       └── SharedModels.swift
├── 📁 SSAFYHub/                  # 메인 앱
│   ├── 📁 Resources/             # 앱 리소스
│   ├── 📁 Sources/               # 소스 코드
│   │   ├── 📁 App/               # 앱 진입점
│   │   ├── 📁 Core/              # 핵심 모듈
│   │   │   ├── 📁 Caching/       # 캐싱 시스템
│   │   │   ├── 📁 ErrorHandling/ # 에러 처리
│   │   │   ├── 📁 Logging/       # 로깅 시스템
│   │   │   ├── 📁 Managers/      # 서비스 매니저
│   │   │   ├── 📁 Network/       # 네트워크 관리
│   │   │   ├── 📁 Testing/       # 테스트 유틸리티
│   │   │   └── 📁 Utilities/     # 유틸리티
│   │   ├── 📁 Screens/           # 화면별 모듈
│   │   │   ├── 📁 Auth/          # 인증 화면
│   │   │   │   ├── AuthFeature.swift
│   │   │   │   ├── AuthView.swift
│   │   │   │   └── 📁 Components/ # 인증 관련 컴포넌트
│   │   │   ├── 📁 Menu/          # 메뉴 화면
│   │   │   │   ├── MenuFeature.swift
│   │   │   │   ├── MainMenuView.swift
│   │   │   │   ├── MenuEditorFeature.swift
│   │   │   │   ├── MenuEditorView.swift
│   │   │   │   ├── MenuTypeInputView.swift
│   │   │   │   └── 📁 Components/ # 메뉴 관련 컴포넌트
│   │   │   └── 📁 Settings/      # 설정 화면
│   │   │       ├── SettingsFeature.swift
│   │   │       └── SettingsView.swift
│   │   ├── 📁 Shared/            # 공유 컴포넌트
│   │   │   └── 📁 Components/    # 재사용 가능한 컴포넌트
│   │   └── SSAFYHubApp.swift     # 앱 진입점
│   └── 📁 Tests/                 # 테스트
│       ├── 📁 UnitTests/         # 단위 테스트
│       ├── 📁 IntegrationTests/  # 통합 테스트
│       └── 📁 UITests/           # UI 테스트
└── 📁 SSAFYHubWidget/            # 위젯 확장
    ├── 📁 Sources/
    │   ├── 📁 Core/              # 위젯 핵심 로직
    │   ├── 📁 UI/                # 위젯 UI
    │   └── 📁 Widget/            # 위젯 구현
    └── SSAFYHubWidget.entitlements
```

## 🛠️ 기술 스택

- **Frontend**: SwiftUI, ComposableArchitecture (TCA)
- **Backend**: Supabase (PostgreSQL, Auth)
- **AI**: OpenAI GPT-4o-mini (이미지 분석)
- **Build System**: Tuist
- **Authentication**: Apple Sign-In, Guest Mode
- **Widget**: WidgetKit (iOS widgets)
- **Architecture**: MVVM + Coordinator Pattern
- **Design System**: 중앙화된 색상 및 테마 관리

## 🚀 시작하기

### 필수 요구사항

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### 설치 및 실행

1. **저장소 클론**
   ```bash
   git clone https://github.com/CobyApp/SSAFYHub.git
   cd SSAFYHub
   ```

2. **의존성 설치**
   ```bash
   tuist install
   ```

3. **환경 변수 설정**
   ```bash
   cp Configuration/env.example .env
   # .env 파일에 실제 API 키 설정
   ```

4. **프로젝트 생성 및 실행**
   ```bash
   tuist generate
   # Xcode에서 프로젝트 열기
   ```

## 📋 주요 모듈

### Core 모듈
- **Caching**: 메모리 및 디스크 캐싱 시스템
- **ErrorHandling**: 중앙화된 에러 처리 및 복구 전략
- **Logging**: 구조화된 로깅 시스템
- **Network**: 네트워크 요청 관리 및 모니터링
- **Managers**: 다양한 서비스 매니저 (Supabase, ChatGPT, Apple Sign-In)

### Screens 모듈 (화면별 구성)
- **Auth**: 인증 화면 (AuthFeature + AuthView + 관련 컴포넌트)
- **Menu**: 메뉴 화면 (MenuFeature + MainMenuView + MenuEditorFeature + MenuEditorView + 관련 컴포넌트)
- **Settings**: 설정 화면 (SettingsFeature + SettingsView)

### Shared 모듈
- **Components**: 여러 화면에서 재사용되는 공통 컴포넌트

## 🍽️ 위젯 기능

### 📱 위젯 종류
- **A타입 위젯**: 오늘의 A타입 식단 표시
- **B타입 위젯**: 오늘의 B타입 식단 표시

### 🔄 자동 업데이트
- **업데이트 시간**: 매일 자정, 점심(12시), 저녁(18시)
- **실시간 동기화**: 메인 앱에서 메뉴 수정 시 위젯 자동 업데이트
- **직접 데이터 로딩**: 위젯이 독립적으로 네트워크에서 최신 데이터 로드

### 📏 지원 크기
- **Small**: 작은 크기 (기본)
- **Medium**: 중간 크기 (더 많은 메뉴 표시)

### 🎨 디자인 특징
- **A타입 위젯**: 주황색 테마, 🍴 아이콘
- **B타입 위젯**: 초록색 테마, 🍃 아이콘

## 🗄️ 데이터베이스 스키마

### Users 테이블
- 사용자 기본 정보
- 캠퍼스별 구분
- 권한 레벨 (게스트/인증된 사용자)

### Menus 테이블
- 날짜별 메뉴 정보
- A타입/B타입 메뉴 배열
- 캠퍼스별 구분
- 수정 이력 추적

## 🚀 사용법

### 메뉴 등록

#### 주간 메뉴 (권장)
- 주 시작일 자동 설정 (현재 날짜 기준)
- A타입, B타입 메뉴를 5일치 입력
- **AI 메뉴 인식**: 식단표 사진 촬영/선택 시 자동으로 메뉴 추출
- **덮어쓰기 확인**: 기존 메뉴가 있을 경우 확인 알럿

#### 메뉴 관리
- 주말 자동 처리 (토/일 → 다음 월요일로 자동 이동)
- 메뉴 수정 시 해당 주 전체 편집 가능

### AI 메뉴 인식

1. 주간 메뉴 모드에서 카메라 또는 앨범 버튼 클릭
2. 식단표 사진 촬영 또는 선택
3. OpenAI GPT-4o-mini가 이미지를 분석하여 메뉴 데이터 자동 추출
4. 추출된 데이터가 입력 필드에 자동으로 채워짐
5. **권한 관리**: 카메라 및 앨범 접근 권한 자동 요청

### 테마 설정

- **라이트 모드**: 밝은 테마
- **다크 모드**: 어두운 테마  
- **시스템 모드**: iOS 시스템 설정 자동 반영
- **즉시 적용**: 테마 변경 시 앱 전체에 즉시 반영

### 위젯 사용

- **A타입 위젯**: 파란색 배경의 A타입 메뉴 표시
- **B타입 위젯**: 초록색 배경의 B타입 메뉴 표시
- **자동 업데이트**: 메뉴 변경 시 위젯 자동 반영
- **오늘 날짜만**: 위젯은 오늘 날짜의 메뉴만 표시

## 🧪 테스트

```bash
# 단위 테스트 실행
tuist test

# 특정 테스트 타겟 실행
tuist test SSAFYHubTests
```

## 📦 빌드

```bash
# 프로젝트 빌드
tuist build

# 특정 타겟 빌드
tuist build SSAFYHub
```

## 🔧 개발 가이드

### 코딩 컨벤션
- Swift API Design Guidelines 준수
- ComposableArchitecture 패턴 사용
- 각 컴포넌트는 별도 파일로 분리
- 명확한 네이밍과 주석 작성

### 아키텍처 패턴
- **MVVM + Coordinator**: README에 명시된 패턴
- **TCA (The Composable Architecture)**: 상태 관리
- **Dependency Injection**: 의존성 주입

## 🔐 보안 및 권한

- **Row Level Security (RLS)**: Supabase에서 데이터 접근 제어
- **사용자별 권한**: 게스트/인증된 사용자 구분
- **캠퍼스별 데이터 격리**: 각 캠퍼스의 메뉴 데이터 독립 관리
- **App Group**: 위젯과 메인 앱 간 안전한 데이터 공유

## 📊 현재 지원 상태

- **대전캠퍼스**: 완전 지원 ✅
- **기타 캠퍼스**: 준비중 (추후 확장 예정) 🚧
- **다크모드**: 완전 지원 ✅
- **위젯**: A타입/B타입 완전 지원 ✅
- **AI 메뉴 인식**: GPT-4o-mini 기반 완전 지원 ✅

## 🐛 문제 해결

### 일반적인 문제

#### 앱이 실행되지 않는 경우
1. **iOS 버전 확인**: iOS 17.0 이상 필요
2. **권한 확인**: 카메라, 앨범 접근 권한 허용
3. **재설치**: 앱 삭제 후 재설치

#### 로그인이 안 되는 경우
1. **Apple ID 확인**: 설정 > Apple ID > iCloud에서 Apple ID 상태 확인
2. **네트워크 연결**: 인터넷 연결 상태 확인
3. **게스트 모드**: 임시로 게스트 모드 사용

#### AI 메뉴 인식이 작동하지 않는 경우
1. **API 키 확인**: OpenAI API 키가 올바르게 설정되었는지 확인
2. **이미지 품질**: 선명하고 메뉴가 잘 보이는 사진 사용
3. **권한 확인**: 카메라 및 앨범 접근 권한 허용

#### 위젯이 업데이트되지 않는 경우
1. **메인 앱 실행**: 최신 데이터 동기화를 위해 앱 실행
2. **위젯 재추가**: 위젯 제거 후 재추가
3. **기기 재부팅**: 시스템 캐시 초기화

### 로그 확인
- **Xcode Console**: 개발 중 디버그 정보 확인
- **기기 로그**: 설정 > 개인정보 보호 및 보안 > 분석 및 개선 > 분석 데이터

## 📝 업데이트 로그

### v1.0.5 (2025년 1월)
- 🏗️ **프로젝트 구조 대폭 개선**
- 📁 화면별 모듈 구조로 재구성 (Screens/Auth, Screens/Menu, Screens/Settings)
- 🔧 중앙화된 에러 처리 시스템 구현
- 📊 구조화된 로깅 시스템 추가
- 🌐 중앙화된 네트워크 관리 시스템
- 💾 계층적 캐싱 시스템 (메모리 + 디스크)
- 🧪 포괄적인 테스트 프레임워크
- 🍽️ 위젯 직접 데이터 로딩 기능
- 📚 문서화 개선 및 통합

### v1.0.1 (2025년 8월)
- 🔧 **버그 수정 및 안정성 개선**
- 🐛 회원탈퇴 시 데이터베이스 정리 로직 개선
- 🔑 Apple Sign-In 키체인 처리 추가 (TestFlight 호환성 향상)
- 🗑️ 메뉴 삭제 시 사용자별 필터링 개선
- 🧹 로컬 데이터 정리 강화
- 📱 네비게이션 화면 전환 문제 해결
- 🎯 전반적인 앱 안정성 향상

### v1.0.0 (2025년 8월)
- 🎉 **초기 릴리즈**
- ✨ Apple Sign-In 지원
- 🍽️ AI 기반 메뉴 인식 (GPT-4o-mini)
- 📱 iOS 위젯 지원 (A타입/B타입)
- 🌙 다크모드 완벽 지원
- 🏫 대전캠퍼스 메뉴 관리
- 🎨 직관적인 UI/UX
- 🔒 Supabase 기반 보안

### 향후 계획
- 🚧 **v1.1.0**: 추가 캠퍼스 지원 (서울, 광주, 구미, 부산)
- 🚧 **v1.2.0**: 알림 기능 및 메뉴 즐겨찾기
- 🚧 **v1.3.0**: 통계 및 분석 기능

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 지원

문제가 있거나 질문이 있으시면 [Issues](https://github.com/CobyApp/SSAFYHub/issues)를 통해 문의해주세요.
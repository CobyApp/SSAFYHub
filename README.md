# SSAFYHub

**버전**: 1.0.0  
**최종 업데이트**: 2025년 8월

SSAFY 학생들을 위한 종합 허브 앱

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

## 🏗️ 기술 스택

- **Frontend**: SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth)
- **AI**: OpenAI GPT-4o-mini API (이미지 분석 지원)
- **Build System**: Tuist
- **Authentication**: Apple Sign-In
- **Architecture**: MVVM + Coordinator Pattern
- **Design System**: 중앙화된 색상 및 테마 관리
- **Widget**: WidgetKit을 사용한 iOS 위젯

## 📱 앱 구조

### 핵심 모델
- **User**: 사용자 정보 및 권한 관리
- **Campus**: 캠퍼스별 설정 및 상태
- **Menu**: A타입/B타입 메뉴 데이터 구조

### 주요 화면
- **AuthView**: 로그인/회원가입
- **MainMenuView**: 메인 메뉴 화면 (주말 자동 처리)
- **MenuEditorView**: 주간 메뉴 편집 (AI 인식 지원)
- **SettingsView**: 설정 및 테마 관리
- **Widget**: A타입/B타입 메뉴 위젯

### 서비스 레이어
- **SupabaseService**: 데이터베이스 연동
- **ChatGPTService**: AI 메뉴 인식
- **AppleSignInService**: Apple 로그인
- **APIKeyManager**: API 키 관리
- **WidgetDataService**: 위젯 데이터 공유
- **ThemeManager**: 다크모드/라이트모드 관리

## 🔧 설정

### OpenAI API 설정

1. [OpenAI Platform](https://platform.openai.com/api-keys)에서 API 키 발급
2. `SSAFYHub/Sources/Services/APIKeyManager.swift` 파일에서 API 키 설정

### Supabase 설정

1. Supabase 프로젝트 생성
2. 환경 변수 설정:
   - `SUPABASE_URL`: Supabase 프로젝트 URL
   - `SUPABASE_ANON_KEY`: Supabase 익명 키

### 권한 설정

앱에서 다음 권한을 요청합니다:
- **카메라**: 메뉴 사진 촬영
- **앨범**: 기존 메뉴 사진 선택

## 📋 요구사항

- iOS 17.0+
- Xcode 15.0+
- Tuist 4.0+
- Apple Developer 계정 (Apple Sign-In 사용 시)

## 📥 설치 방법

### App Store (권장)
- App Store에서 "SSAFYHub" 검색 후 설치
- iOS 17.0 이상 필요

### 개발자 빌드
```bash
# 저장소 클론
git clone https://github.com/your-username/SSAFYHub.git
cd SSAFYHub

# Tuist 설치
curl -Ls https://install.tuist.io | bash

# 프로젝트 생성
tuist generate

# 의존성 설치
tuist fetch

# 프로젝트 빌드
tuist build
```

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

## 🛠️ 개발 환경 설정

```bash
# Tuist 설치
curl -Ls https://install.tuist.io | bash

# 프로젝트 생성
tuist generate

# 의존성 설치
tuist fetch

# 프로젝트 빌드
tuist build
```

## 🎨 디자인 시스템

- **중앙화된 색상 관리**: AppDesignSystem.swift에서 모든 색상 통합 관리
- **다크모드 자동 지원**: iOS 시스템 색상 활용으로 완벽한 다크모드 지원
- **일관된 UI**: 모든 화면에서 동일한 디자인 언어 사용
- **접근성**: 고대비 색상과 적절한 폰트 크기로 가독성 향상

## 📝 라이선스

© 2025 Coby

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 등록해 주세요.

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

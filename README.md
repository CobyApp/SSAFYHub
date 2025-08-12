# SSAFYHub

SSAFY 학생들을 위한 종합 허브 앱

## 🚀 주요 기능

- **Apple Sign-In**: 안전한 로그인 시스템
- **게스트 모드**: 제한된 기능으로 체험 가능
- **메뉴 관리**: 단일일/주간 메뉴 등록 및 편집
- **AI 메뉴 인식**: OpenAI GPT-4o-mini API를 사용한 이미지 기반 메뉴 자동 추출
- **캠퍼스별 관리**: 서울, 대전, 광주, 구미, 부산 캠퍼스 지원 (현재 대전캠퍼스만 활성화)

## 🏗️ 기술 스택

- **Frontend**: SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth)
- **AI**: OpenAI GPT-4o-mini API (이미지 분석 지원)
- **Build System**: Tuist
- **Authentication**: Apple Sign-In
- **Architecture**: MVVM + Coordinator Pattern

## 📱 앱 구조

### 핵심 모델
- **User**: 사용자 정보 및 권한 관리
- **Campus**: 캠퍼스별 설정 및 상태
- **Menu**: A타입/B타입 메뉴 데이터 구조

### 주요 화면
- **AuthView**: 로그인/회원가입
- **CampusSelectionView**: 캠퍼스 선택
- **MainMenuView**: 메인 메뉴 화면
- **MenuEditorView**: 메뉴 편집
- **MenuDisplayView**: 메뉴 표시

### 서비스 레이어
- **SupabaseService**: 데이터베이스 연동
- **ChatGPTService**: AI 메뉴 인식

- **AppleSignInService**: Apple 로그인
- **APIKeyManager**: API 키 관리

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

#### 단일일 메뉴
- 날짜 선택 후 A타입, B타입 메뉴 입력
- 수동으로 메뉴 항목 추가/삭제

#### 주간 메뉴
- 주 시작일 선택 (월요일 기준)
- A타입, B타입 메뉴를 5일치 입력
- **AI 메뉴 인식**: 식단표 사진 촬영/선택 시 자동으로 메뉴 추출

### AI 메뉴 인식

1. 주간 메뉴 모드에서 카메라 또는 앨범 버튼 클릭
2. 식단표 사진 촬영 또는 선택
3. OpenAI GPT-4o-mini가 이미지를 분석하여 메뉴 데이터 자동 추출
4. 추출된 데이터가 입력 필드에 자동으로 채워짐



## 🔐 보안 및 권한

- **Row Level Security (RLS)**: Supabase에서 데이터 접근 제어
- **사용자별 권한**: 게스트/인증된 사용자 구분
- **캠퍼스별 데이터 격리**: 각 캠퍼스의 메뉴 데이터 독립 관리

## 📊 현재 지원 상태

- **대전캠퍼스**: 완전 지원 ✅
- **기타 캠퍼스**: 준비중 (추후 확정 예정) 🚧

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

## 📝 라이선스

© 2025 Coby

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 등록해 주세요.

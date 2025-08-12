# SSAFYHub

SSAFY 학생들을 위한 종합 허브 앱

## 🚀 주요 기능

- **Apple Sign-In**: 안전한 로그인
- **게스트 모드**: 제한된 기능으로 체험
- **메뉴 관리**: 단일일/주간 메뉴 등록 및 편집
- **AI 메뉴 인식**: Gemini API를 사용한 이미지 기반 메뉴 자동 추출

## 🔧 설정

### Gemini API 설정

1. [Google AI Studio](https://makersuite.google.com/app/apikey)에서 API 키 발급
2. `SSAFYHub/Sources/Services/GeminiService.swift` 파일 열기
3. `apiKey` 변수에 발급받은 API 키 입력:

```swift
private let apiKey = "YOUR_ACTUAL_API_KEY_HERE"
```

### 권한 설정

앱에서 다음 권한을 요청합니다:
- **카메라**: 메뉴 사진 촬영
- **앨범**: 기존 메뉴 사진 선택

## 📱 사용법

### 메뉴 등록

#### 단일일 메뉴
- 날짜 선택 후 A타입, B타입 메뉴 입력
- 수동으로 메뉴 항목 추가

#### 주간 메뉴
- 주 시작일 선택 (월요일 기준)
- A타입, B타입 메뉴를 5일치 입력
- **AI 메뉴 인식**: 식단표 사진 촬영/선택 시 자동으로 메뉴 추출

### AI 메뉴 인식

1. 주간 메뉴 모드에서 카메라 또는 앨범 버튼 클릭
2. 식단표 사진 촬영 또는 선택
3. Gemini AI가 이미지를 분석하여 메뉴 데이터 자동 추출
4. 추출된 데이터가 입력 필드에 자동으로 채워짐

## 🏗️ 기술 스택

- **Frontend**: SwiftUI
- **Backend**: Supabase (PostgreSQL + Auth)
- **AI**: Google Gemini Pro Vision API
- **Build System**: Tuist
- **Authentication**: Apple Sign-In

## 📋 요구사항

- iOS 17.0+
- Xcode 15.0+
- Tuist 4.0+

## 🔐 환경 변수

- `SUPABASE_URL`: Supabase 프로젝트 URL
- `SUPABASE_ANON_KEY`: Supabase 익명 키
- `GEMINI_API_KEY`: Google Gemini API 키

## 📝 라이선스

2025 Coby

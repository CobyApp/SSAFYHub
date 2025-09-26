# 🍽️ SSAFYHub

<div align="center">

**SSAFY 학생들을 위한 스마트 식단 관리 앱**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.6-purple.svg)](https://github.com/CobyApp/SSAFYHub/releases)

</div>

## ✨ 개요

SSAFYHub는 삼성 청년 소프트웨어 아카데미(SSAFY) 캠퍼스의 식단 정보를 제공하고 관리할 수 있는 iOS 앱입니다. AI 기반 메뉴 인식과 실시간 위젯을 통해 학생들의 식단 관리를 더욱 편리하게 만들어줍니다.

## 🚀 핵심 기능

### 🔐 인증 시스템
- **Apple Sign-In**: 안전하고 빠른 로그인
- **게스트 모드**: 제한된 기능으로 체험 가능
- **자동 세션 관리**: 앱 재시작 시 자동 로그인

### 🍽️ 메뉴 관리
- **주간 메뉴 편집**: 한 번에 5일치 메뉴 등록
- **AI 메뉴 인식**: GPT-4o-mini로 식단표 사진 자동 분석
- **실시간 동기화**: 메뉴 변경 시 즉시 반영
- **캠퍼스별 관리**: 대전캠퍼스 지원 (추후 확장 예정)

### 📱 위젯 지원
- **A타입/B타입 위젯**: 홈 화면에서 바로 메뉴 확인
- **자동 업데이트**: 매일 자정, 점심, 저녁 자동 갱신
- **직접 데이터 로딩**: 앱 실행 없이도 최신 메뉴 표시

### 🎨 사용자 경험
- **다크모드 완벽 지원**: 라이트/다크/시스템 테마
- **직관적인 UI**: SwiftUI 기반 모던 디자인
- **접근성**: 고대비 색상과 적절한 폰트 크기

## 🏗️ 기술 스택

<table>
<tr>
<td><strong>Frontend</strong></td>
<td>SwiftUI, ComposableArchitecture (TCA)</td>
</tr>
<tr>
<td><strong>Backend</strong></td>
<td>Supabase (PostgreSQL, Auth)</td>
</tr>
<tr>
<td><strong>AI</strong></td>
<td>OpenAI GPT-4o-mini (이미지 분석)</td>
</tr>
<tr>
<td><strong>Build System</strong></td>
<td>Tuist</td>
</tr>
<tr>
<td><strong>Authentication</strong></td>
<td>Apple Sign-In, Guest Mode</td>
</tr>
<tr>
<td><strong>Widget</strong></td>
<td>WidgetKit (iOS widgets)</td>
</tr>
<tr>
<td><strong>Architecture</strong></td>
<td>MVVM + Coordinator Pattern</td>
</tr>
</table>

## 📁 프로젝트 구조

```
SSAFYHub/
├── 📁 Configuration/              # 설정 파일
│   └── env.example               # 환경 변수 예시
├── 📁 Scripts/                   # 빌드 스크립트
├── 📁 SharedModels/              # 공유 모델
├── 📁 SSAFYHub/                  # 메인 앱
│   ├── 📁 Sources/
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
│   │   │   ├── 📁 Menu/          # 메뉴 화면
│   │   │   └── 📁 Settings/      # 설정 화면
│   │   ├── 📁 Shared/            # 공유 컴포넌트
│   │   └── SSAFYHubApp.swift     # 앱 진입점
│   └── 📁 Tests/                 # 테스트
└── 📁 SSAFYHubWidget/            # 위젯 확장
```

## 🚀 빠른 시작

### 📋 필수 요구사항

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+
- **Tuist**: 4.0+

### ⚡ 설치 및 실행

```bash
# 1. 저장소 클론
git clone https://github.com/CobyApp/SSAFYHub.git
cd SSAFYHub

# 2. 의존성 설치
tuist install

# 3. 환경 변수 설정
cp Configuration/env.example .env
# .env 파일에 실제 API 키 설정

# 4. 프로젝트 생성 및 실행
tuist generate
# Xcode에서 프로젝트 열기
```

### 🔧 환경 설정

#### OpenAI API 설정
1. [OpenAI Platform](https://platform.openai.com/api-keys)에서 API 키 발급
2. `.env` 파일에 `OPENAI_API_KEY` 설정

#### Supabase 설정
1. Supabase 프로젝트 생성
2. `.env` 파일에 다음 설정:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

## 🍽️ 위젯 가이드

### 📱 위젯 종류
- **A타입 위젯**: 주황색 테마, A타입 메뉴 표시
- **B타입 위젯**: 초록색 테마, B타입 메뉴 표시

### 🔄 자동 업데이트
- **업데이트 시간**: 매일 자정, 점심(12시), 저녁(18시)
- **실시간 동기화**: 메인 앱에서 메뉴 수정 시 위젯 자동 업데이트
- **직접 데이터 로딩**: 위젯이 독립적으로 네트워크에서 최신 데이터 로드

### 📏 지원 크기
- **Small**: 작은 크기 (기본)
- **Medium**: 중간 크기 (더 많은 메뉴 표시)

## 🧪 테스트

```bash
# 단위 테스트 실행
tuist test

# 특정 테스트 타겟 실행
tuist test SSAFYHubTests

# 빌드 테스트
tuist build
```

## 🔐 보안

- **Row Level Security (RLS)**: Supabase에서 데이터 접근 제어
- **사용자별 권한**: 게스트/인증된 사용자 구분
- **캠퍼스별 데이터 격리**: 각 캠퍼스의 메뉴 데이터 독립 관리
- **App Group**: 위젯과 메인 앱 간 안전한 데이터 공유
- **API 키 보안**: 환경변수 기반 관리

## 📊 현재 지원 상태

| 기능 | 상태 | 비고 |
|------|------|------|
| 대전캠퍼스 | ✅ 완전 지원 | 메뉴 조회, 편집, AI 인식 |
| 다크모드 | ✅ 완전 지원 | 라이트/다크/시스템 테마 |
| 위젯 | ✅ 완전 지원 | A타입/B타입 위젯 |
| AI 메뉴 인식 | ✅ 완전 지원 | GPT-4o-mini 기반 |
| 기타 캠퍼스 | 🚧 준비중 | 추후 확장 예정 |

## 🐛 문제 해결

### 일반적인 문제

<details>
<summary><strong>앱이 실행되지 않는 경우</strong></summary>

1. **iOS 버전 확인**: iOS 17.0 이상 필요
2. **권한 확인**: 카메라, 앨범 접근 권한 허용
3. **재설치**: 앱 삭제 후 재설치

</details>

<details>
<summary><strong>로그인이 안 되는 경우</strong></summary>

1. **Apple ID 확인**: 설정 > Apple ID > iCloud에서 Apple ID 상태 확인
2. **네트워크 연결**: 인터넷 연결 상태 확인
3. **게스트 모드**: 임시로 게스트 모드 사용

</details>

<details>
<summary><strong>AI 메뉴 인식이 작동하지 않는 경우</strong></summary>

1. **API 키 확인**: OpenAI API 키가 올바르게 설정되었는지 확인
2. **이미지 품질**: 선명하고 메뉴가 잘 보이는 사진 사용
3. **권한 확인**: 카메라 및 앨범 접근 권한 허용

</details>

<details>
<summary><strong>위젯이 업데이트되지 않는 경우</strong></summary>

1. **메인 앱 실행**: 최신 데이터 동기화를 위해 앱 실행
2. **위젯 재추가**: 위젯 제거 후 재추가
3. **기기 재부팅**: 시스템 캐시 초기화

</details>

## 📝 업데이트 로그

### 🆕 v1.0.6 (2025년 1월)
- 🏗️ **프로젝트 구조 대폭 개선**
- 📁 화면별 모듈 구조로 재구성 (Screens/Auth, Screens/Menu, Screens/Settings)
- 🔧 중앙화된 에러 처리 시스템 구현
- 📊 구조화된 로깅 시스템 추가
- 🌐 중앙화된 네트워크 관리 시스템
- 💾 계층적 캐싱 시스템 (메모리 + 디스크)
- 🧪 포괄적인 테스트 프레임워크
- 🍽️ 위젯 직접 데이터 로딩 기능
- 📚 문서화 개선 및 통합
- 🔒 API 키 보안 강화

### v1.0.5 (2025년 1월)
- 🍽️ 위젯 초기 설치 시 데이터 로딩 개선
- 🌐 위젯이 항상 네트워크 요청을 시도하여 최신 데이터 로드
- 📱 로그인 후 위젯에서 실제 API 데이터 표시
- 🔧 네트워크 실패 시 캐시된 데이터 또는 기본 데이터 사용

### v1.0.1 (2025년 8월)
- 🔧 버그 수정 및 안정성 개선
- 🐛 회원탈퇴 시 데이터베이스 정리 로직 개선
- 🔑 Apple Sign-In 키체인 처리 추가
- 🗑️ 메뉴 삭제 시 사용자별 필터링 개선

### v1.0.0 (2025년 8월)
- 🎉 초기 릴리즈
- ✨ Apple Sign-In 지원
- 🍽️ AI 기반 메뉴 인식 (GPT-4o-mini)
- 📱 iOS 위젯 지원 (A타입/B타입)
- 🌙 다크모드 완벽 지원
- 🏫 대전캠퍼스 메뉴 관리

## 🗺️ 향후 계획

### 🚧 v1.1.0 (예정)
- 🏫 **추가 캠퍼스 지원**: 서울, 광주, 구미, 부산
- 🔔 **알림 기능**: 메뉴 변경 알림
- ⭐ **메뉴 즐겨찾기**: 자주 먹는 메뉴 저장

### 🚧 v1.2.0 (예정)
- 📊 **통계 및 분석**: 식단 패턴 분석
- 🎯 **개인화**: 사용자 맞춤 추천
- 📈 **트렌드 분석**: 인기 메뉴 통계

### 🚧 v1.3.0 (예정)
- 🤝 **소셜 기능**: 메뉴 공유 및 리뷰
- 🏆 **게임화**: 식단 관리 챌린지
- 🔗 **외부 연동**: 캘린더, 건강 앱 연동

## 🤝 기여하기

SSAFYHub 프로젝트에 기여하고 싶으시다면:

1. **Fork** the Project
2. **Create** your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your Changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the Branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### 📋 기여 가이드라인

- **코딩 컨벤션**: Swift API Design Guidelines 준수
- **아키텍처**: ComposableArchitecture 패턴 사용
- **테스트**: 새로운 기능에 대한 테스트 작성
- **문서화**: 명확한 주석과 README 업데이트

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 지원

- **이슈 리포트**: [GitHub Issues](https://github.com/CobyApp/SSAFYHub/issues)
- **기능 요청**: [GitHub Discussions](https://github.com/CobyApp/SSAFYHub/discussions)
- **문서**: [Wiki](https://github.com/CobyApp/SSAFYHub/wiki)

## 🙏 감사의 말

- **SSAFY**: 삼성 청년 소프트웨어 아카데미
- **OpenAI**: GPT-4o-mini API 제공
- **Supabase**: 백엔드 인프라 제공
- **Point-Free**: ComposableArchitecture 프레임워크

---

<div align="center">

**SSAFYHub로 더 스마트한 식단 관리 시작하기** 🍽️

[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/app/ssafyhub/id1234567890)

</div>
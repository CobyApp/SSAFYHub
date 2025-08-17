# 🍽️ SSAFYHub 위젯

SSAFYHub 앱의 식단 정보를 홈 화면에서 바로 확인할 수 있는 위젯입니다.

## ✨ 기능

### 📱 위젯 종류
- **A타입 위젯**: 오늘의 A타입 식단 표시
- **B타입 위젯**: 오늘의 B타입 식단 표시

### 🔄 자동 업데이트
- **업데이트 시간**: 매일 자정, 점심(12시), 저녁(18시)
- **실시간 동기화**: 메인 앱에서 메뉴 수정 시 위젯 자동 업데이트

### 📏 지원 크기
- **Small**: 작은 크기 (기본)
- **Medium**: 중간 크기 (더 많은 메뉴 표시)

## 🚀 설치 방법

### 1. 위젯 추가
1. 홈 화면에서 길게 터치
2. 좌측 상단의 "+" 버튼 탭
3. "SSAFYHub 위젯" 검색
4. 원하는 크기 선택 후 "위젯 추가" 탭

### 2. 위젯 설정
1. 위젯을 길게 터치
2. "위젯 편집" 선택
3. A타입 또는 B타입 선택

## 🎨 디자인 특징

### A타입 위젯
- **색상**: 주황색 테마
- **아이콘**: 🍴 (포크와 나이프)
- **표시**: 최대 3개 메뉴 + 추가 개수

### B타입 위젯
- **색상**: 초록색 테마
- **아이콘**: 🍃 (잎사귀)
- **표시**: 최대 3개 메뉴 + 추가 개수

## 🔧 기술적 구현

### 📊 데이터 공유
- **App Group**: `group.com.coby.ssafyhub`
- **UserDefaults**: 메인 앱과 위젯 간 데이터 동기화
- **JSON**: Menu 모델 직렬화/역직렬화

### 🏗️ 아키텍처
```
SharedModels (Framework)
├── Menu.swift
├── Campus.swift
└── 공통 데이터 모델

SSAFYHub (Main App)
├── 위젯 데이터 공유
└── WidgetDataService

SSAFYHubWidget (Extension)
├── A타입 위젯
├── B타입 위젯
└── 타임라인 프로바이더
```

### 📱 위젯 생명주기
1. **시스템 요청**: iOS가 위젯 업데이트 요청
2. **데이터 로드**: App Group에서 메뉴 데이터 읽기
3. **UI 렌더링**: SwiftUI로 위젯 화면 구성
4. **타임라인**: 다음 업데이트 시간 예약

## 🛠️ 개발자 정보

### 📁 파일 구조
```
SSAFYHubWidget/
├── Sources/
│   ├── SSAFYHubWidgetBundle.swift    # 위젯 번들
│   ├── SSAFYHubATypeWidget.swift     # A타입 위젯
│   ├── SSAFYHubBTypeWidget.swift     # B타입 위젯
│   ├── SSAFYHubTimelineProvider.swift # 데이터 제공자
│   └── SSAFYHubWidgetPreview.swift   # 프리뷰
├── Resources/
│   ├── Assets.xcassets/              # 이미지 리소스
│   └── Info.plist                    # 설정 파일
└── SSAFYHubWidget.entitlements      # 권한 설정
```

### 🔑 Entitlements
- **App Groups**: `group.com.coby.ssafyhub`
- **WidgetKit**: 위젯 확장 지원

### 📦 의존성
- **SharedModels**: 공통 데이터 모델
- **WidgetKit**: iOS 위젯 프레임워크
- **SwiftUI**: 사용자 인터페이스

## 🐛 문제 해결

### 위젯이 업데이트되지 않는 경우
1. 메인 앱 실행하여 최신 데이터 동기화
2. 위젯 제거 후 재추가
3. 기기 재부팅

### 데이터가 표시되지 않는 경우
1. App Group 권한 확인
2. 메인 앱에서 메뉴 데이터 확인
3. 위젯 캐시 초기화

## 📈 향후 계획

### 🆕 추가 기능
- [ ] 위젯에서 직접 메뉴 수정
- [ ] 주간 메뉴 미리보기
- [ ] 캠퍼스별 위젯 설정
- [ ] 다크모드 지원

### 🎯 최적화
- [ ] 배터리 사용량 최적화
- [ ] 메모리 사용량 개선
- [ ] 네트워크 요청 최소화

---

**개발자**: SSAFYHub Team  
**버전**: 1.0.1  
**최종 업데이트**: 2025년 8월  
**호환성**: iOS 17.0+

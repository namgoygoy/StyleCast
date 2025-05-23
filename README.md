# StyleCast

날씨 기반 패션 추천 iOS 앱

## 🚀 프로젝트 설정

### 1. API 키 설정

이 앱은 OpenWeatherMap API를 사용합니다. 다음 단계를 따라 API 키를 설정해주세요:

1. **OpenWeatherMap API 키 발급**
   - [OpenWeatherMap](https://openweathermap.org/api)에서 무료 계정 생성
   - API 키 발급받기

2. **설정 파일 생성**
   ```bash
   # Config-Sample.xcconfig 파일을 복사하여 Config.xcconfig 생성
   cp Config-Sample.xcconfig Config.xcconfig
   ```

3. **API 키 입력**
   - `Config.xcconfig` 파일을 열어 `YOUR_API_KEY_HERE`를 실제 API 키로 교체
   ```
   OPENWEATHER_API_KEY = your_actual_api_key_here
   ```

### 2. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. iOS 앱 추가 (Bundle ID: 프로젝트의 Bundle Identifier 사용)
3. `GoogleService-Info.plist` 파일을 다운로드하여 `Firebase/` 폴더에 추가

## 🏗️ 프로젝트 구조

```
StyleCast/
├── StyleCast/                 # 메인 앱 코드
│   ├── Models/               # 데이터 모델
│   ├── Views/                # SwiftUI 뷰
│   ├── ViewModels/           # MVVM 뷰모델
│   ├── Services/             # API 및 서비스 레이어
│   └── Assets.xcassets/      # 이미지 및 컬러 에셋
├── Config-Sample.xcconfig    # 설정 파일 템플릿
├── Config.xcconfig          # 실제 설정 파일 (Git에서 제외)
└── Firebase/                # Firebase 설정 파일
```

## 🔧 주요 기능

- 🌤️ **실시간 날씨 정보**: OpenWeatherMap API 연동
- 👔 **패션 추천**: 날씨에 따른 맞춤형 옷차림 추천
- 🏷️ **스타일 태그**: 스트릿/미니멀 스타일 선택
- 👨‍👩‍ **성별 구분**: 남성/여성 패션 분리
- 📍 **위치 기반**: GPS 또는 도시 검색
- 💾 **사용자 관리**: Firebase 인증 및 프로필

## ⚠️ 주의사항

- `Config.xcconfig` 파일은 Git에 커밋하지 마세요
- API 키는 절대 소스코드에 하드코딩하지 마세요
- Firebase 설정 파일도 민감한 정보가 포함되어 있으니 주의하세요

## 🛡️ 보안

- API 키는 Xcode 빌드 설정을 통해 안전하게 관리됩니다
- 실제 키 파일들은 `.gitignore`에 의해 Git에서 제외됩니다
- 샘플 설정 파일만 저장소에 포함됩니다

## 📱 요구사항

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+ 
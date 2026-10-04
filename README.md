# book-summary-flutter
book summary flutter app

## 로컬 API 주소

앱 실행 시 플랫폼에 맞는 설정 파일을 지정한다.

```sh
flutter run --dart-define-from-file=config/dev.android.json
flutter run --dart-define-from-file=config/dev.ios.json
```

실기기나 별도 서버를 사용할 때는 `API_BASE_URL`을 해당 서버의 `/api/v1` 주소로 지정한다.

## 실제 서버 연동 테스트

서버와 Android 에뮬레이터를 실행한 뒤 장치 ID를 지정한다.

```sh
flutter test integration_test/live_summary_api_test.dart -d emulator-5554 \
  --dart-define-from-file=config/dev.android.json --dart-define=RUN_LIVE_API=true
```

Firebase SDK 익명 로그인과 앱 인증 인터셉터를 사용하여 책 생성·목록 조회,
텍스트 제출, 2초 간격 작업 조회, 원문·요약 조회, 책 회차·글자 수 집계를 검증한다.
매 실행마다 새 익명 사용자와 `연동 테스트` 책을 생성하며 실제 Gemini를 호출한다.
토큰과 API 키는 출력하지 않는다. `RUN_LIVE_API=true`를 지정한 경우에만 실행한다.

## 기기 OCR

한국어 ML Kit 모델을 앱에 포함해 연결 없이 텍스트를 추출한다. 이미지는 서버로
전송하지 않으며 추출·편집한 텍스트는 메모리에서만 유지한다.

- Android: API 24 이상
- iOS: 15.5 이상. ML Kit의 [Apple Silicon 시뮬레이터 지원 제한](https://developers.google.com/ml-kit/known-issues#ios_issues)으로 실제 OCR은 실기기에서 검증한다.
- iOS 네이티브 의존성은 `ios/Podfile`의 CocoaPods 설정으로 설치한다.

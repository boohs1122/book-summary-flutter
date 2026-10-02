# book-summary-flutter
book summary flutter app

## 로컬 API 주소

앱 실행 시 플랫폼에 맞는 설정 파일을 지정한다.

```sh
flutter run --dart-define-from-file=config/dev.android.json
flutter run --dart-define-from-file=config/dev.ios.json
```

실기기나 별도 서버를 사용할 때는 `API_BASE_URL`을 해당 서버의 `/api/v1` 주소로 지정한다.

## 기기 OCR

한국어 ML Kit 모델을 앱에 포함해 연결 없이 텍스트를 추출한다. 이미지는 서버로
전송하지 않으며 추출·편집한 텍스트는 메모리에서만 유지한다.

- Android: API 24 이상
- iOS: 15.5 이상. ML Kit의 [Apple Silicon 시뮬레이터 지원 제한](https://developers.google.com/ml-kit/known-issues#ios_issues)으로 실제 OCR은 실기기에서 검증한다.
- iOS 네이티브 의존성은 `ios/Podfile`의 CocoaPods 설정으로 설치한다.

# book-summary-flutter
book summary flutter app

## 로컬 API 주소

앱 실행 시 플랫폼에 맞는 설정 파일을 지정한다.

```sh
flutter run --dart-define-from-file=config/dev.android.json
flutter run --dart-define-from-file=config/dev.ios.json
```

실기기나 별도 서버를 사용할 때는 `API_BASE_URL`을 해당 서버의 `/api/v1` 주소로 지정한다.

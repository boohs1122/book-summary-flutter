# Flutter 코드 규칙

## 상태 관리

Riverpod을 사용한다. 비동기 상태는 `AsyncValue`로 다루고 로딩·에러 상태를
직접 정의하지 않는다.

```dart
ref.watch(booksProvider).when(
  loading: () => const LoadingView(),
  error:   (e, _) => ErrorView(error: e, onRetry: ...),
  data:    (books) => BookListView(books: books),
);
```

- provider는 기능 폴더의 `presentation/provider/`에 둔다
- 화면에서 직접 레포지토리를 호출하지 않는다. provider를 거친다
- 폴링은 `Stream` provider로 구현한다

## 위젯

- 화면은 `ConsumerWidget` 또는 `ConsumerStatefulWidget`
- 한 파일에 위젯 하나를 원칙으로 하되, 해당 화면에서만 쓰는 작은 위젯은 같은 파일 허용
- `build` 메서드가 80줄을 넘으면 위젯으로 분리한다
- 색과 간격은 `Theme.of(context)`에서 가져온다. 하드코딩한 색상값을 쓰지 않는다

## 네이밍

| 대상 | 규칙 | 예 |
|---|---|---|
| 파일 | snake_case | `book_list_screen.dart` |
| 클래스 | PascalCase | `BookListScreen` |
| 화면 | `{대상}{역할}Screen` | `QuizResultScreen` |
| provider | `{대상}Provider` | `booksProvider` |
| DTO | `{대상}Dto` | `BookDto` |

화면 파일명은 화면 흐름 문서(docs/02)의 식별자와 대응시킨다.

## 에러 처리

- 네트워크 오류는 스낵바로 안내하고 재시도 수단을 제공한다. 화면을 이탈시키지 않는다
- 빈 상태에는 안내 문구와 다음 행동 버튼을 둔다
- 예외를 화면에 그대로 노출하지 않는다. `core/error`에서 사용자 문구로 변환한다

## 금지

- `print` 사용 금지. 로깅이 필요하면 `debugPrint` 또는 로거를 쓴다
- `setState`와 Riverpod 혼용 금지. 애니메이션 컨트롤러 등 위젯 내부 상태만 예외
- 하드코딩한 문자열을 화면에 직접 쓰지 않는다. 화면 파일 상단 상수로 모은다

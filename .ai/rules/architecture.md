# 아키텍처 규칙

## 구조

기능별 3계층. UseCase 계층은 두지 않는다.

```
lib/
├── core/
│   ├── network/        Dio 클라이언트, 인터셉터, 에러 변환
│   ├── error/          예외 정의
│   ├── theme/          Material 3 테마
│   └── router/         화면 경로
├── features/
│   ├── library/        홈(책 목록), 책 상세
│   ├── capture/        촬영, OCR, 텍스트 확인, 책 선택
│   ├── summary/        요약 생성 대기, 요약 보기
│   └── quiz/           퀴즈 풀이, 채점 결과
└── main.dart
```

각 기능 폴더는 동일한 내부 구조를 가진다.

```
features/{name}/
├── data/
│   ├── dto/            API 응답 모델 (json_serializable)
│   └── {name}_repository_impl.dart
├── domain/
│   ├── model/          앱 내부 모델
│   └── {name}_repository.dart      인터페이스
└── presentation/
    ├── screen/         화면 위젯
    ├── widget/         해당 기능 전용 위젯
    └── provider/       Riverpod provider, 상태
```

## 의존 방향

```
presentation → domain ← data
```

- `presentation`은 `domain`만 안다. `data`를 직접 참조하지 않는다
- `data`는 `domain`의 인터페이스를 구현한다
- `domain`은 아무것도 참조하지 않는다. Flutter 의존성도 갖지 않는다

## UseCase를 두지 않는 이유

로직 대부분이 서버에 있다. 앱이 하는 일은 OCR 실행, API 호출, 폴링, 화면 표시이며
여러 레포지토리를 조합하는 복잡한 규칙이 없다. UseCase를 넣으면 레포지토리를
한 번 호출하고 끝나는 클래스가 기능마다 쌓인다.

Flutter 공식 아키텍처 가이드도 Domain 계층을 "필요할 때만" 추가하도록 안내한다.
규칙이 복잡해지는 시점에 도입한다.

## DTO와 모델을 분리하는 이유

API 응답이 바뀌어도 화면 코드가 영향받지 않게 한다. 변환은 `data` 계층에서만
일어나며, `presentation`은 `domain/model`만 다룬다.

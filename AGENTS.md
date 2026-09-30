# BookSummaryApp

책 사진을 찍으면 기기에서 텍스트를 추출하고, 서버가 만든 요약과 퀴즈로
학습하는 Flutter 앱. 서버는 별도 저장소 `BookSummaryApi`(Kotlin + Spring Boot).

## 규칙

작업 전 해당하는 규칙 문서를 읽는다.

- [.ai/rules/architecture.md](.ai/rules/architecture.md) — 레이어 구조와 의존 방향
- [.ai/rules/coding.md](.ai/rules/coding.md) — 코드 스타일, 상태 관리
- [.ai/rules/git.md](.ai/rules/git.md) — 브랜치, 커밋 메시지, git 훅
- [.ai/rules/pr.md](.ai/rules/pr.md) — PR 작성과 병합
- [.ai/rules/testing.md](.ai/rules/testing.md) — 테스트 대상과 작성 기준
- [.ai/rules/docs.md](.ai/rules/docs.md) — 문서 작성 규칙

## 스킬

절차는 `.agents/skills/`에 둔다. `.claude/skills`는 이 폴더를 가리키는 심볼릭 링크다.

- [commit](.agents/skills/commit/SKILL.md) — 커밋 절차
- [pr](.agents/skills/pr/SKILL.md) — PR 생성과 병합 절차

## 맥락

- [.ai/context/domain.md](.ai/context/domain.md) — 용어 정의
- [.ai/context/api-contract.md](.ai/context/api-contract.md) — 서버 계약 요약
- [docs/](docs/) — 기획, 화면 흐름, API 명세, 개발 규약

## 하지 않는 것

- 이미지를 서버로 전송하지 않는다. OCR은 기기에서 처리한다
- UseCase 계층을 만들지 않는다. 이 규모에서는 과하다
- 화면에 정답을 내려받지 않는다. 퀴즈 채점은 서버가 한다
- 기획 문서를 임의로 수정하지 않는다. 결정 사항 변경은 사용자 확인을 거친다
- 커밋 메시지와 PR 본문에 `Co-Authored-By` 등 AI 작업 표기를 넣지 않는다
- 저장소에 올라가는 파일·커밋 메시지·PR에는 제품과 개발에 관한 내용만 쓴다. 작성자의 개인 사정이나 개발 외 목적은 적지 않는다
- 커밋과 push는 사용자 확인을 거친다. 커밋 전에 작성자가 `boohs1122`인지 확인한다

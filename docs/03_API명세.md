# BookSummaryApp API 명세

작성일: 2026-09-20
상태: 초안
관련 문서: [01_기획.md](01_기획.md), [02_화면흐름.md](02_화면흐름.md)

## 1. 공통 규약

### 기본 정보

| 항목 | 값 |
|---|---|
| Base URL | `https://{host}/api/v1` |
| 형식 | JSON (UTF-8) |
| 인증 | `Authorization: Bearer {Firebase ID Token}` |
| 시각 표기 | ISO-8601 UTC (`2026-09-20T09:12:33Z`) |

모든 엔드포인트는 인증을 요구한다. 서버는 Firebase Admin SDK로 토큰을
검증하고 `uid`를 사용자 식별자로 사용한다. 익명 로그인 계정도 동일하게 처리한다.

별도 사용자 등록 절차는 없다. 서버는 `uid`를 리소스 소유자로 저장하고,
다른 `uid`의 리소스 접근은 `FORBIDDEN`으로 거절한다 (01 문서 4장).

### 에러 응답

모든 에러는 아래 형식을 따른다.

```json
{
  "error": {
    "code": "TEXT_TOO_SHORT",
    "message": "추출된 텍스트가 너무 짧습니다."
  }
}
```

| HTTP | code | 상황 |
|---|---|---|
| 400 | `TEXT_TOO_SHORT` | 텍스트 100자 미만 |
| 400 | `INVALID_REQUEST` | 필수 필드 누락, 타입 불일치 |
| 401 | `UNAUTHORIZED` | 토큰 없음·만료·검증 실패 |
| 403 | `FORBIDDEN` | 타 사용자 리소스 접근 |
| 404 | `NOT_FOUND` | 대상 리소스 없음 (책·회차·퀴즈) |
| 409 | `JOB_IN_PROGRESS` | 동일 대상에 진행 중인 작업 존재 |
| 429 | `RATE_LIMITED` | 요청 한도 초과 |
| 502 | `LLM_FAILED` | LLM 호출 실패 |
| 502 | `LLM_INVALID_RESPONSE` | LLM 응답이 스키마에 부합하지 않음 |
| 500 | `INTERNAL_ERROR` | 그 외 서버 오류 |

`message`는 사용자 노출 가능한 한국어 문구로 작성한다. 클라이언트는 분기 판단에
`code`만 사용하며 `message`를 파싱하지 않는다.

### 비동기 작업 규약

LLM 호출이 포함된 요청(요약 생성, 퀴즈 생성)은 즉시 완료되지 않는다.
해당 요청은 `202 Accepted`와 `jobId`를 반환하고, 클라이언트는 작업 상태
엔드포인트를 2초 간격으로 조회한다.

```
요청 → 202 { jobId } → GET /jobs/{jobId} 반복 → DONE → 결과 조회
```

## 2. 엔드포인트 목록

| # | Method | Path | 용도 | 화면 |
|---|---|---|---|---|
| B1 | GET | `/books` | 책 목록 조회 | S1 · S6 |
| B2 | POST | `/books` | 책 생성 | S6 |
| B3 | GET | `/books/{bookId}` | 책 상세 및 회차 목록 | S2 |
| B4 | DELETE | `/books/{bookId}` | 책 삭제 | S1 |
| B5 | PATCH | `/books/{bookId}` | 책 제목 수정 | S1 · S2 |
| E1 | GET | `/documents?bookId={bookId}` | 회차 목록 조회 (B3에 포함) | S2 |
| E2 | POST | `/documents` | 텍스트 등록 및 요약 생성 요청 | S5 · S6 |
| E3 | GET | `/jobs/{jobId}` | 작업 상태 조회 | S7 · S8 |
| E4 | GET | `/documents/{documentId}` | 문서 상세 및 요약 조회 | S8 |
| E5 | DELETE | `/documents/{documentId}` | 회차 삭제 | S2 |
| E6 | POST | `/documents/{documentId}/quiz` | 퀴즈 생성 요청 | S8 |
| E7 | GET | `/documents/{documentId}/quiz` | 퀴즈 조회 | S8 · S9 |
| E8 | POST | `/quizzes/{quizId}/results` | 풀이 결과 저장 | S10 |
| E9 | POST | `/documents/{documentId}/retry` | 요약 재생성 요청 | S2 · S7 |

---

## B1. 책 목록 조회

```
GET /books
```

**응답 200**

```json
{
  "items": [
    {
      "bookId": "bok_01HX...",
      "title": "운영체제 교재",
      "documentCount": 3,
      "totalCharCount": 13270,
      "lastStudiedAt": "2026-09-20T09:20:41Z",
      "latestScore": { "correct": 2, "total": 3 },
      "createdAt": "2026-09-14T11:02:00Z"
    }
  ],
  "nextCursor": null
}
```

`lastStudiedAt`은 소속 회차의 최근 활동 시각이다. 목록은 이 값 내림차순으로 정렬한다.
`latestScore`는 가장 최근 응시 결과이며 기록이 없으면 `null`.

S6 책 선택 화면도 같은 엔드포인트를 사용한다.

---

## B2. 책 생성

```
POST /books
```

**요청**

```json
{ "title": "운영체제 교재" }
```

| 필드 | 타입 | 제약 |
|---|---|---|
| `title` | string | 1자 이상 100자 이하 |

**응답 201**

```json
{ "bookId": "bok_01HY...", "title": "운영체제 교재", "createdAt": "2026-09-20T10:31:00Z" }
```

같은 제목의 책을 막지 않는다. 동명 교재를 따로 관리할 수 있어야 하며,
중복 판단은 사용자 몫이다.

**에러**: `INVALID_REQUEST`(400)

---

## B3. 책 상세 및 회차 목록

```
GET /books/{bookId}
```

**응답 200**

```json
{
  "bookId": "bok_01HX...",
  "title": "운영체제 교재",
  "documentCount": 3,
  "totalCharCount": 13270,
  "documents": [
    {
      "documentId": "doc_01HX...",
      "sequence": 1,
      "status": "DONE",
      "title": "프로세스 관리",
      "preview": null,
      "charCount": 5240,
      "hasQuiz": true,
      "latestScore": { "correct": 2, "total": 3 },
      "createdAt": "2026-09-14T11:02:00Z"
    },
    {
      "documentId": "doc_01HZ...",
      "sequence": 2,
      "status": "FAILED",
      "title": null,
      "preview": "메모리 계층 구조는 속도와 용량의",
      "charCount": 3120,
      "hasQuiz": false,
      "latestScore": null,
      "createdAt": "2026-09-18T20:14:00Z"
    }
  ]
}
```

회차는 `sequence` 오름차순으로 반환한다. 책은 순서대로 읽는 대상이므로
최신순이 아니다. 모든 상태의 회차를 포함한다.

**에러**: `NOT_FOUND`(404), `FORBIDDEN`(403)

---

## B4. 책 삭제

```
DELETE /books/{bookId}
```

**응답 204** (본문 없음)

소속 회차와 그 요약·퀴즈·풀이 결과를 모두 삭제한다. 클라이언트는 삭제 전
회차 수를 명시한 확인 다이얼로그를 노출한다.

**에러**: `NOT_FOUND`(404), `FORBIDDEN`(403)

---

## B5. 책 제목 수정

```
PATCH /books/{bookId}
Authorization: Bearer <Firebase ID 토큰>
Content-Type: application/json
```

**요청**

```json
{ "title": "수정할 책 제목" }
```

| 필드 | 타입 | 제약 |
|---|---|---|
| `title` | string | 필수. 앞뒤 공백을 제거한 후 1~100자 |

**응답 200**

```json
{ "bookId": "bok_01HY...", "title": "수정할 책 제목" }
```

인증된 사용자 소유의 책만 수정한다. 응답의 `title`은 앞뒤 공백이 제거된 값이다.
책 ID·생성 시각과 연결된 문서·요약·퀴즈·풀이 결과는 유지한다.
수정된 제목은 B1 책 목록, B3 책 상세, E4 문서 상세의 `bookTitle`에 반영된다.
앱은 수정 성공 후 해당 조회 상태를 갱신한다.

**에러**: `INVALID_REQUEST`(400 — 제목 누락·null·빈 값·공백만 있거나 공백 제거 후 100자 초과),
`UNAUTHORIZED`(401), `FORBIDDEN`(403 — 타인 소유 책), `NOT_FOUND`(404)

오류 응답은 공통 `{ "error": { "code": "...", "message": "..." } }` 형식을 따른다.

---

## E1. 회차 목록 조회

```
GET /documents?bookId={bookId}&cursor={cursor}&size=20
```

B3이 회차 목록을 포함하므로 1차 구현에서는 사용하지 않는다. 회차가 많은 책에
페이지네이션이 필요해지면 이 엔드포인트로 분리한다.

**응답 200**

```json
{
  "items": [
    {
      "documentId": "doc_01HX...",
      "status": "DONE",
      "title": "운영체제의 프로세스 관리",
      "preview": null,
      "charCount": 5240,
      "hasQuiz": true,
      "latestScore": { "correct": 2, "total": 3 },
      "createdAt": "2026-09-20T09:12:33Z"
    },
    {
      "documentId": "doc_01HY...",
      "status": "FAILED",
      "title": null,
      "preview": "프로세스는 실행 중인 프로그램을 의미한다. 운영체제는",
      "charCount": 3120,
      "hasQuiz": false,
      "latestScore": null,
      "createdAt": "2026-09-20T10:02:11Z"
    }
  ],
  "nextCursor": "eyJpZCI6..."
}
```

| 필드 | 설명 |
|---|---|
| `status` | `PROCESSING` · `DONE` · `FAILED` |
| `title` | 요약의 `title`. 요약이 없으면 `null` |
| `preview` | 원문 앞부분 40자. `title`이 있으면 `null` |
| `latestScore` | 응시 기록이 없으면 `null` |

**모든 상태의 문서를 포함한다.** 요약에 실패한 문서를 제외하면 추출·교정을 거친
텍스트에 접근할 경로가 사라지므로, 목록에 남기고 재시도(E9)를 제공한다.
`nextCursor`가 `null`이면 마지막 페이지.

---

## E2. 텍스트 등록 및 요약 생성 요청

```
POST /documents
```

**요청**

```json
{
  "bookId": "bok_01HX...",
  "text": "프로세스는 실행 중인 프로그램을 의미한다. ..."
}
```

| 필드 | 타입 | 제약 |
|---|---|---|
| `bookId` | string | 필수. 소유한 책의 식별자 |
| `text` | string | 100자 이상 10,000자 이하 |

`sequence`는 서버가 해당 책에 남아 있는 회차의 최대 순번 + 1로 부여한다.
회차가 없으면 1부터 시작하며, 삭제 후에도 남아 있는 회차의 순번은 유지한다.
새 책에 첫 회차를 넣는 경우 클라이언트가 B2로 책을 먼저 만들고 그
`bookId`를 전달한다.

클라이언트는 페이지별 텍스트를 순서대로 병합해 단일 문자열로 전송한다.
10,000자 초과분은 클라이언트에서 절단하며, 서버는 초과 시 `INVALID_REQUEST`로 거부한다.

**응답 202**

```json
{
  "jobId": "job_01HX...",
  "status": "PROCESSING"
}
```

**에러**: `TEXT_TOO_SHORT`(400), `INVALID_REQUEST`(400), `RATE_LIMITED`(429)

---

## E3. 작업 상태 조회

```
GET /jobs/{jobId}
```

**응답 200 — 진행 중**

```json
{
  "jobId": "job_01HX...",
  "type": "SUMMARY",
  "status": "PROCESSING",
  "createdAt": "2026-09-20T09:12:33Z"
}
```

**응답 200 — 완료**

```json
{
  "jobId": "job_01HX...",
  "type": "SUMMARY",
  "status": "DONE",
  "documentId": "doc_01HX...",
  "createdAt": "2026-09-20T09:12:33Z",
  "completedAt": "2026-09-20T09:12:45Z"
}
```

**응답 200 — 실패**

```json
{
  "jobId": "job_01HX...",
  "type": "SUMMARY",
  "status": "FAILED",
  "documentId": "doc_01HX...",
  "createdAt": "2026-09-20T09:12:33Z",
  "completedAt": "2026-09-20T09:12:45Z",
  "error": { "code": "LLM_FAILED", "message": "요약 생성에 실패했습니다." }
}
```

| 필드 | 값 |
|---|---|
| `type` | `SUMMARY` \| `QUIZ` |
| `status` | `PROCESSING` \| `DONE` \| `FAILED` |

`DONE`과 `FAILED` 응답에는 `documentId`와 `completedAt`을 포함한다.
요약 실패 시 반환된 `documentId`로 E9를 호출해 보관된 원문으로 재시도한다.

`type`이 `QUIZ`인 경우 완료 응답에 `documentId`와 함께 `quizId`를 포함한다.

클라이언트는 `jobId`를 로컬에 보관해 앱 재실행 시 상태를 재조회한다.
작업 레코드는 완료 후 24시간 보관한다.

**작업 취소 엔드포인트는 두지 않는다.** 대기 화면의 취소는 화면 이탈만
의미하며 서버 작업은 계속 진행되어 결과가 저장된다. LLM 호출이 시작된 뒤에는
중단해도 비용이 절약되지 않고, 결과를 남기는 편이 재시도보다 낫다.

---

## E4. 문서 상세 및 요약 조회

```
GET /documents/{documentId}
```

**응답 200**

```json
{
  "documentId": "doc_01HX...",
  "bookId": "bok_01HX...",
  "bookTitle": "운영체제 교재",
  "sequence": 1,
  "status": "DONE",
  "charCount": 5240,
  "extractedText": "프로세스는 실행 중인 프로그램을 ...",
  "summary": {
    "title": "운영체제의 프로세스 관리",
    "keyPoints": [
      { "type": "definition", "heading": "프로세스의 정의", "detail": "실행 중인 프로그램으로, 메모리에 적재되어 CPU를 할당받는 작업 단위." },
      { "type": "mechanism", "heading": "프로세스 상태 전이", "detail": "생성·준비·실행·대기·종료 다섯 상태를 오가며 스케줄러가 전이를 관리한다." }
    ],
    "terms": [
      { "term": "PCB", "meaning": "프로세스 제어 블록. 프로세스의 상태 정보를 담는 자료구조." }
    ]
  },
  "quiz": {
    "exists": true,
    "quizId": "quz_01HX...",
    "questionCount": 3,
    "latestScore": { "correct": 2, "total": 3 }
  },
  "createdAt": "2026-09-20T09:12:33Z"
}
```

`keyPoints[].type`은 `definition` · `mechanism` · `cause` ·
`comparison` · `caution` · `example` 중 하나다. 클라이언트는 유형별로 색과 라벨을 달리해 표시하며, 정의되지 않은
값이 오면 `definition`으로 취급한다.

`quiz.exists`가 `false`이면 나머지 필드는 `null`.
`status`가 `DONE`이 아니면 `summary`와 `quiz`는 `null`이며 `extractedText`만 반환한다.
문서 제목은 `summary.title`이 유일한 출처다. `Document`에는 제목 컬럼을 두지 않는다.

**에러**: `NOT_FOUND`(404), `FORBIDDEN`(403)

---

## E5. 회차 삭제

```
DELETE /documents/{documentId}
```

**응답 204** (본문 없음)

연관된 요약, 퀴즈, 풀이 결과를 함께 삭제한다.

**에러**: `NOT_FOUND`(404), `FORBIDDEN`(403)

---

## E6. 퀴즈 생성 요청

```
POST /documents/{documentId}/quiz
```

요청 본문 없음. 문서당 퀴즈는 1세트만 보유하므로 이미 존재하면 생성하지 않는다.

**응답 202 — 신규 생성 시작**

```json
{
  "jobId": "job_01HY...",
  "status": "PROCESSING"
}
```

**응답 200 — 이미 존재**

```json
{
  "quizId": "quz_01HX...",
  "status": "DONE"
}
```

클라이언트는 상태 코드로 분기한다. 202면 E3 폴링 후 E7 조회, 200이면 즉시 E7 조회.

**에러**: `NOT_FOUND`(404), `JOB_IN_PROGRESS`(409), `RATE_LIMITED`(429)

---

## E7. 퀴즈 조회

```
GET /documents/{documentId}/quiz
```

**응답 200**

```json
{
  "quizId": "quz_01HX...",
  "documentId": "doc_01HX...",
  "questions": [
    {
      "index": 0,
      "question": "프로세스 상태 전이에서 준비 상태의 의미로 옳은 것은?",
      "options": [
        "CPU를 할당받아 명령을 수행 중인 상태",
        "CPU 할당을 기다리는 상태",
        "입출력 완료를 기다리는 상태",
        "자원을 반납하고 종료된 상태"
      ]
    }
  ],
  "createdAt": "2026-09-20T09:13:10Z"
}
```

풀이 중 정답 노출을 방지하기 위해 `answerIndex`와 `explanation`은 포함하지 않는다.
해당 정보는 E8 응답으로만 전달한다.

**에러**: `NOT_FOUND`(404)

---

## E8. 풀이 결과 저장

```
POST /quizzes/{quizId}/results
```

**요청**

```json
{
  "answers": [
    { "index": 0, "selected": 1 },
    { "index": 1, "selected": 3 },
    { "index": 2, "selected": null }
  ]
}
```

`selected`가 `null`이면 미응답으로 처리하며 오답으로 채점한다.

**응답 201**

```json
{
  "resultId": "res_01HX...",
  "score": { "correct": 2, "total": 3 },
  "items": [
    {
      "index": 0,
      "question": "프로세스 상태 전이에서 준비 상태의 의미로 옳은 것은?",
      "options": ["...", "...", "...", "..."],
      "selected": 1,
      "answerIndex": 1,
      "correct": true,
      "explanation": "준비 상태는 실행에 필요한 자원을 모두 확보하고 CPU 할당만 기다리는 상태이다."
    }
  ],
  "solvedAt": "2026-09-20T09:20:41Z"
}
```

채점은 서버에서 수행한다. 재응시 시 기존 결과를 덮어쓰지 않고 레코드를 누적 생성한다.

**에러**: `NOT_FOUND`(404), `INVALID_REQUEST`(400)

---

## E9. 요약 재생성 요청

```
POST /documents/{documentId}/retry
```

요청 본문 없음. `status`가 `FAILED`인 문서에 한해 보관된 `extractedText`로
요약 생성을 다시 시도한다. 재촬영과 재전송이 필요 없다.

**응답 202**

```json
{
  "jobId": "job_01HZ...",
  "status": "PROCESSING"
}
```

문서 상태는 `PROCESSING`으로 전환된다.

**에러**: `NOT_FOUND`(404), `JOB_IN_PROGRESS`(409), `INVALID_REQUEST`(400 — `status`가 `FAILED`가 아님), `RATE_LIMITED`(429)

---

## 3. 서버 내부 처리

### 요약 생성 (E2 이후)

```
텍스트 수신
  → 정제 (연속 공백·줄바꿈 정리, 하이픈 분철 결합)
  → 글자 수로 목표 핵심 항목 수 산정
  → LLM 호출 (구조화 출력 스키마 강제)
  → 응답 검증 (항목 수, 필수 필드)
  → Document + Summary 저장
  → Job 상태 DONE 갱신
```

### 퀴즈 생성 (E6 이후)

```
문서 원문 + 요약 핵심 항목 조회
  → 문항 수 결정 (1차: 3 고정)
  → LLM 호출 (구조화 출력 스키마 강제)
  → 응답 검증 (문항 수, 선택지 4개, answerIndex 범위)
  → Quiz 저장
  → Job 상태 DONE 갱신
```

검증 실패 시 1회 재요청하고, 재차 실패하면 `LLM_INVALID_RESPONSE`로 작업을 종료한다.

## 4. 요약 실패 처리 흐름

```
S7 요약 생성 대기 → FAILED 수신
  ├─ 그 자리에서 재시도 → E9 호출
  └─ 앱 종료·이탈
       → 문서는 status FAILED 로 보관
       → S2 회차 목록에 실패 배지로 노출
       → 카드 선택 → 재시도 확인 → E9 호출 → S7 이동
```

텍스트는 서버에 남아 있으므로 어느 경로로 돌아오든 재촬영이 필요 없다.

## 5. 후속 확정 대상

- 요청 한도 정책 (사용자당 일일 요약 생성 횟수)
- 목록 페이지네이션 크기
- 실패 문서 보관 기간
- 회차가 많은 책의 페이지네이션 전환 시점
- 책 제목 수정 엔드포인트
- 검색 엔드포인트 `GET /search?q=` — 1차 미도입. 설계안은 01 문서 8장

S6 책 선택 화면의 필터는 B1 응답을 클라이언트에서 거르는 방식이며 별도
엔드포인트를 두지 않는다.

실측 후 조정할 값은 [01_기획.md](01_기획.md) 8장에서 일괄 관리한다.

---
name: code-tester
description: >
  브라우저 UI 기능 테스트 스킬. 실제 브라우저에서
  UI 조작과 결과 검증을 수행하여 프론트엔드 기능의 정상 동작을 확인한다.
  코드 리뷰 통과 후 또는 명시적 UI 테스트 요청 시 사용한다.
  트리거 키워드: "브라우저 테스트", "UI 테스트", "화면 테스트",
  "동작 확인해줘", "E2E 테스트", "browser test"
---

# code-tester Skill

## 테스트 루프 (최대 2회)

아래 루프를 `iteration = 0`부터 시작하여 최대 2회(`iteration < 2`) 반복한다.

### LOOP START

#### Step 1: 테스트 시나리오 소스 결정

우선순위:
1. 사용자가 직접 제시한 시나리오
2. code-planner 에이전트 출력의 테스트 시나리오 섹션
3. `git diff` 기반 자동 생성 → 자동 생성 시 사용자 컨펌 필요

#### Step 2: 전제조건 확인

- 개발 서버 URL: `.claude/rules/build-commands.md` 참조
- 로그인 상태 확인 필요 여부
- 테스트 데이터 존재 여부

전제조건 미충족 시 사용자에게 안내하고 해결 후 진행.

#### Step 3: 브라우저 테스트 실행

```
Agent tool 호출:
  - subagent_type: "crinity-dev:browser-tester"
  - prompt: |
      아래 테스트 시나리오를 실행하라.
      [시나리오 목록]
      개발 서버 URL: [build-commands.md에서 확인한 URL]
  - description: "브라우저 UI 테스트"
```

#### 결과 판정

에이전트 결과의 **"종합"** 섹션에서 **판정**을 확인한다.

| 판정 | 처리 |
|------|------|
| **전체 PASS** (SKIP 포함) | 루프 종료 — 완료. SKIP 항목은 수동 확인 권고 출력 |
| **FAIL 1건 이상** | FAIL 상세를 확인하고, `iteration++` 후 개발 루프로 복귀 (아래 참조) |

**FAIL 시 개발 루프 복귀:**

FAIL 원인과 에이전트 리포트를 포함하여 code-developer 스킬을 재호출한다:

```
Skill tool 호출:
  - skill: "crinity-dev:code-developer"
```

code-developer 스킬의 개발 루프가 완료된 후, 다시 이 테스트 루프의 LOOP START로 돌아온다.

### LOOP END

**루프 2회 소진 시:** 사용자에게 보고하고 수동 테스트 전환을 권고한다.

```
테스트 루프 2회 완료 후에도 FAIL이 해소되지 않았습니다.
수동 테스트로 전환하시겠습니까?
```

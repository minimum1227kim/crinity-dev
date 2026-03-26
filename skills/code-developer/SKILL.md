---
name: code-developer
description: >
  코드 작성 스킬. 백엔드와 프론트엔드 코드를 프로젝트 컨벤션에 맞게 작성한다.
  사전 조건: code-planner 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태.
  트리거 키워드: "코드 작성 시작", "개발 시작", "구현 시작"
---

# code-developer Skill

사전 조건: `code-planner` 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태

## 시작 전 준비

1. 현재 대화에서 **계획 텍스트**(code-planner 에이전트 출력)를 확인한다.
2. `.claude/tasks/` 에서 status: IN_PROGRESS인 `*_task.md` 파일 확인:
   - 존재 시: 태스크 체크리스트를 작업 순서의 참고로 사용
   - 없으면: code-planner 계획 텍스트를 그대로 사용
3. 계획에서 **스택 유형** 확인: `backend-only` / `frontend-only` / `fullstack`

---

## 개발 루프 (최대 3회)

아래 루프를 `iteration = 0`부터 시작하여 최대 3회(`iteration < 3`) 반복한다.

### LOOP START

#### Step 1: 백엔드 개발 (백엔드 태스크가 있을 때)

```
Agent tool 호출:
  - subagent_type: "crinity-dev:backend-developer"
  - prompt: |
      아래 계획에 따라 백엔드 코드를 작성하라.
      [계획 텍스트의 백엔드 관련 부분 포함]
      [iteration > 0인 경우: 이전 리뷰 피드백도 포함]
  - description: "백엔드 코드 작성"
```

task.md 존재 시: 완료된 태스크의 체크박스를 업데이트한다.

```
Skill tool 호출:
  - skill: "crinity-dev:task-manager"
  - args: "update"
```

#### Step 2: 프론트엔드 개발 (프론트엔드 태스크가 있을 때)

```
Agent tool 호출:
  - subagent_type: "crinity-dev:frontend-developer"
  - prompt: |
      아래 계획에 따라 프론트엔드 코드를 작성하라.
      [계획 텍스트의 프론트엔드 관련 부분 포함]
      [iteration > 0인 경우: 이전 리뷰 피드백도 포함]
  - description: "프론트엔드 코드 작성"
```

**Step 1 & 2 병렬 처리 판단:**
- `fullstack`: 프론트엔드 API 계층이 백엔드에 의존하므로, API 계층을 제외한 프론트엔드 태스크는 백엔드와 **동시에 Agent tool을 호출**하여 병렬 실행 가능
- `backend-only` / `frontend-only`: 해당 없음 (단일 에이전트만 실행)
- task.md의 `Depends on` 필드에 교차 의존이 있으면 순차 실행

task.md 존재 시: Skill tool → `"crinity-dev:task-manager"` args `"update"` 호출

#### Step 3: 코드 리팩토링 (첫 회만)

**iteration == 0일 때만 실행한다.** iteration > 0이면 이 단계를 건너뛴다.

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-refactorer"
  - prompt: "git diff 기반 변경 파일의 컨벤션 위반 수정, 중복 제거, 품질 개선"
  - description: "코드 품질 개선"
```

task.md 존재 시: Skill tool → `"crinity-dev:task-manager"` args `"update"` 호출

#### Step 4: 검증 게이트 1 — 빌드 검증

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-verifier"
  - prompt: "변경 모듈의 빌드, 테스트, lint를 검증하라. 실패 시 내부에서 최대 3회 수정 후 재시도."
  - description: "빌드/테스트 검증"
```

**결과 판정:** 에이전트 결과에서 **"종합 판정"** 줄을 확인한다.

| 판정 | 처리 |
|------|------|
| **PASS** | Step 5로 진행 |
| **FAIL** (에이전트 내부 3회 재시도 후에도 실패) | `iteration++`, LOOP START로 복귀 |

task.md 존재 시: Skill tool → `"crinity-dev:task-manager"` args `"update"` 호출

#### Step 5: 검증 게이트 2 — 코드 리뷰

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-reviewer"
  - prompt: |
      git 변경 내역을 리뷰하라.
      [계획 텍스트가 있으면 함께 전달하여 계획 대비 구현 검증도 수행]
  - description: "코드 리뷰"
```

**결과 판정:** 에이전트 결과의 **"종합"** 섹션에서 CRITICAL/HIGH/MEDIUM/LOW 카운트를 확인한다.

| 결과 | 처리 |
|------|------|
| **CRITICAL > 0** 또는 **HIGH > 0** | `iteration++`, LOOP START로 복귀. 리뷰 피드백을 다음 iteration의 Step 1~2 prompt에 포함 |
| **MEDIUM만 존재** (CRITICAL=0, HIGH=0) | 사용자에게 수정 여부를 질문한다. 수정 시 `iteration++` 후 LOOP START, 스킵 시 루프 종료 |
| **LOW only** (CRITICAL=0, HIGH=0, MEDIUM=0) | 루프 종료 — **PASS** (경고만 출력) |
| **위반 없음** | 루프 종료 — **PASS** |

task.md 존재 시: Skill tool → `"crinity-dev:task-manager"` args `"update"` 호출

### LOOP END

**루프 3회 소진 시:** 미해결 리뷰 항목을 사용자에게 보고하고 수동 대응을 요청한다.

---

## 루프 종료 후: 테스트 전이 판단

개발 루프가 PASS로 종료된 후, **프론트엔드 변경 포함 여부**를 확인한다:

| 조건 | 처리 |
|------|------|
| 프론트엔드 변경 **없음** (backend-only) | 워크플로우 완료 |
| 프론트엔드 변경 **있음** | 사용자에게 브라우저 테스트 진행 여부를 확인한다 |

사용자가 브라우저 테스트를 승인한 경우:

```
Skill tool 호출:
  - skill: "crinity-dev:code-tester"
```

**완료 시**: task.md 모든 체크박스 완료 확인 후:

```
Skill tool 호출:
  - skill: "crinity-dev:task-manager"
  - args: "complete"
```

---
name: task-manager
description: >
  대규모 기능 개발 시 .claude/tasks/{feature}_task.md 파일을 생성·관리한다.
  shrimp-task-manager MCP를 대체한다. code-planner가 복잡도 threshold 초과 시 자동 호출하거나,
  사용자가 직접 진행 상황을 확인할 때 사용한다.
  트리거 키워드: "태스크 생성", "작업 관리", "진행 상황", "태스크 업데이트", "task list", "진행 상황 보여줘"
---

# task-manager Skill

트리거 키워드: "태스크 생성", "작업 관리", "진행 상황", "태스크 업데이트", "task list", "진행 상황 보여줘"

## 자동 트리거 조건

`code-planner` 스킬 Step 4의 복잡도 threshold 기준을 따른다 (SSOT: `code-planner SKILL.md` Step 4).
threshold 충족 시 `code-planner` 스킬이 이 스킬의 `create` 오퍼레이션을 호출한다.

## 오퍼레이션

### create — 태스크 파일 생성

code-planner 완료 후, 위 조건 충족 시 자동 실행.

1. 기능 슬러그 결정 (영문 kebab-case, 예: `mail-config`, `contact-group`)
2. `.claude/tasks/{feature-slug}_task.md` 생성 (아래 형식 참고)
3. code-planner 계획의 태스크 목록, UI 결정 사항을 파일에 기록

### update — 체크박스 업데이트

code-developer 루프에서 각 에이전트 완료 후 자동 실행.

1. `.claude/tasks/` 에서 status: IN_PROGRESS 파일 찾기
2. 완료된 태스크의 `- [ ]` → `- [x]` 변경
3. Progress Log에 행 추가: `| {timestamp} | {agent} | {task} | DONE | {notes} |`

### list — 전체 태스크 현황

사용자 요청 시 (`"진행 상황 보여줘"`, `"task list"`).

1. `.claude/tasks/*_task.md` 파일 전체 읽기
2. 각 파일의 status, 완료/전체 체크박스 수 집계
3. 요약 테이블 출력

### complete — 완료 처리

모든 체크박스 `[x]` 시 자동 실행.

1. `## Status: IN_PROGRESS` → `## Status: COMPLETED`
2. `- Completed: -` → `- Completed: {YYYY-MM-DD HH:mm}`
3. `- Last Updated:` 갱신

## task.md 파일 형식

```markdown
# Task: {기능명}

## Status: IN_PROGRESS
- Created: {YYYY-MM-DD HH:mm}
- Last Updated: {YYYY-MM-DD HH:mm}
- Completed: -

## Feature Overview
{1~3문장 기능 설명}

## UI Design Decisions

| # | 컴포넌트 | 선택 옵션 | 사유 | 목업 파일 |
|---|---------|----------|------|----------|
| 1 | {컴포넌트명} | Option {N}: {제목} | {사유} | {feature-slug}_ui_options.html |

(UI 결정 없는 경우 이 섹션 생략)

## Task Checklist

### Backend
- [ ] `Task 1`: {설명} — @backend-developer
  - Target: `{파일경로}` (NEW)
  - Depends on: -
- [ ] `Task 2`: {설명} — @backend-developer
  - Target: `{파일경로}` (MODIFY)
  - Depends on: Task 1

### Frontend
- [ ] `Task 3`: {설명} — @frontend-developer
  - Target: `{파일경로}` (NEW)
  - Depends on: -
- [ ] `Task 4`: {설명} — @frontend-developer
  - Target: `{파일경로1}`, `{파일경로2}` (MODIFY)
  - Depends on: Task 3

### Integration
- [ ] `Task N`: i18n — @frontend-developer
  - Target: `{i18n-path}` (경로는 `.claude/rules/frontend-rules.md` i18n 섹션 참조)
- [ ] `Task N+1`: Code refactoring — @code-refactorer
- [ ] `Task N+2`: Build verification — @code-verifier
- [ ] `Task N+3`: Code review — @code-reviewer

## Progress Log

| Timestamp | Agent | Task | Result | Notes |
|-----------|-------|------|--------|-------|
| {YYYY-MM-DD HH:mm} | code-planner | 파일 생성 | - | 태스크 {N}개 |
```

## 주의사항

- `.claude/tasks/` 디렉토리는 `.gitignore`에 포함되어 있으므로 git에 커밋되지 않는다
- 완료된 task.md 파일은 삭제하지 않고 COMPLETED 상태로 유지한다
- 동시에 여러 기능 개발 중인 경우, 각 기능별 별도 파일로 관리한다

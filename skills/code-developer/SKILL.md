---
name: code-developer
description: >
  코드 작성 스킬. 백엔드와 프론트엔드 코드를 프로젝트 컨벤션에 맞게 작성한다.
  사전 조건: code-planner 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태.
  트리거 키워드: "코드 작성 시작", "개발 시작", "구현 시작"
---

# code-developer Skill

트리거 키워드: "코드 작성 시작", "개발 시작", "구현 시작"

사전 조건: `code-planner` 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태

## 실행 흐름

**시작 전**:
1. 백엔드 태스크 → `backend-developer` 에이전트, 프론트엔드 태스크 → `frontend-developer` 에이전트를 실행한다.
2. `.claude/tasks/` 에서 status: IN_PROGRESS인 `*_task.md` 파일 확인
   - 존재 시: 태스크 체크리스트를 작업 순서의 참고로 사용
   - 없으면: code-planner 계획 텍스트를 그대로 사용

개발 루프 (최대 3회):

1. `backend-developer` 역할 에이전트 실행 (백엔드 태스크 있을 때)
   - task.md 존재 시: 완료된 Backend 태스크 체크박스 `[ ]` → `[x]` 업데이트 + Progress Log 추가
2. `frontend-developer` 역할 에이전트 실행 (프론트엔드 태스크 있을 때)
   - task.md 존재 시: 완료된 Frontend 태스크 체크박스 업데이트 + Progress Log 추가

**1과 2의 병렬 처리 판단** (`code-planner` 스킬 Step 4의 병렬 처리 규칙을 따른다):
   - `fullstack`: 프론트엔드 API 계층이 백엔드 API 계층에 의존하므로, API 계층을 제외한 프론트엔드 태스크는 백엔드와 병렬 가능
   - `backend-only` / `frontend-only`: 해당 없음 (단일 에이전트만 실행)
   - task.md의 `Depends on` 필드에 교차 의존이 있으면 순차 실행
3. `code-refactorer` 에이전트 실행 (첫 회만)
   - task.md 존재 시: Integration > Code refactoring 태스크 체크박스 업데이트
4. `code-verifier` 에이전트 실행
   - task.md 존재 시: Integration > Build verification 태스크 체크박스 업데이트
5. `code-reviewer` 에이전트 실행
   - task.md 존재 시: Integration > Code review 태스크 체크박스 업데이트

**완료 시**: task.md 모든 체크박스 완료 → `task-manager` 스킬 (complete 오퍼레이션) 호출

## 리뷰 결과 처리

| 결과 | 처리 |
|------|------|
| CRITICAL / HIGH | 루프 반복 (Step 1부터, 최대 3회) |
| MEDIUM | 사용자 판단 요청 |
| LOW only | 통과 (경고만 출력) |

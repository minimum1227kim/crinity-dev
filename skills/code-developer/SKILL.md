---
name: code-developer
description: >
  코드 작성 스킬. 백엔드와 프론트엔드 코드를 프로젝트 컨벤션에 맞게 작성한다.
  사전 조건: code-planner 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태.
  트리거 키워드: "코드 작성 시작", "개발 시작", "구현 시작"
---

# code-developer Skill

사전 조건: `code-planner` 스킬을 통해 계획이 수립되고 사용자 컨펌이 완료된 상태

## 실행 흐름

**시작 전**:
1. 백엔드 태스크 → `backend-developer` 에이전트, 프론트엔드 태스크 → `frontend-developer` 에이전트를 실행한다.
2. `.claude/tasks/` 에서 status: IN_PROGRESS인 `*_task.md` 파일 확인
   - 존재 시: 태스크 체크리스트를 작업 순서의 참고로 사용
   - 없으면: code-planner 계획 텍스트를 그대로 사용

개발 루프 (최대 3회):

1. `backend-developer` 에이전트 실행 (백엔드 태스크 있을 때)
   - task.md 존재 시: `task-manager` 스킬 (update 오퍼레이션) 호출
2. `frontend-developer` 에이전트 실행 (프론트엔드 태스크 있을 때)
   - task.md 존재 시: `task-manager` 스킬 (update 오퍼레이션) 호출

**1과 2의 병렬 처리 판단**:
   - `fullstack`: 프론트엔드 API 계층이 백엔드 API 계층에 의존하므로, API 계층을 제외한 프론트엔드 태스크는 백엔드와 병렬 가능
   - `backend-only` / `frontend-only`: 해당 없음 (단일 에이전트만 실행)
   - task.md의 `Depends on` 필드에 교차 의존이 있으면 순차 실행
3. `code-refactorer` 에이전트 실행 (첫 회만)
   - task.md 존재 시: `task-manager` 스킬 (update 오퍼레이션) 호출
4. **검증 게이트 1** — `code-verifier` 에이전트 실행
   - task.md 존재 시: `task-manager` 스킬 (update 오퍼레이션) 호출
   - **통과 기준**: 빌드 성공 + 변경 모듈 테스트 PASS + lint PASS (세 가지 모두)
   - FAIL 시: 개발 단계(Step 1-2)로 복귀하지 않고, verifier가 내부에서 최대 3회 재시도
   - verifier 3회 실패 시: 루프 반복 (Step 1부터)
5. **검증 게이트 2** — `code-reviewer` 에이전트 실행
   - task.md 존재 시: `task-manager` 스킬 (update 오퍼레이션) 호출
   - **검증 범위**: 컨벤션/보안/아키텍처 규칙 + **계획 대비 구현 정합성** + **기능적 정합성**
   - 계획 대비 검증: 계획된 파일·API·DTO가 모두 올바르게 구현되었는지 확인
   - 기능적 검증: FE↔BE API 매칭, Store↔DTO 구조, 에러 체인 완전성, i18n 동기화

**완료 시**: task.md 모든 체크박스 완료 → `task-manager` 스킬 (complete 오퍼레이션) 호출

## 리뷰 결과 처리

| 결과 | 처리 |
|------|------|
| CRITICAL / HIGH | 루프 반복 (Step 1부터, 최대 3회) |
| MEDIUM | 사용자 판단 요청 |
| LOW only | 통과 (경고만 출력) |

> **주의**: reviewer가 "계획 대비 누락 구현"을 HIGH로 보고한 경우, 해당 항목을 구현한 후 다시 verifier → reviewer를 순서대로 실행한다.

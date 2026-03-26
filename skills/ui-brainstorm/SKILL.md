---
name: ui-brainstorm
description: >
  UI 설계 의사결정이 필요할 때 HTML 목업을 생성하여 브라우저에서 옵션을 비교·선택한다.
  code-planner가 UI 결정 게이트에서 내부적으로 호출하거나, 사용자가 직접 요청할 수 있다.
  트리거 키워드: "UI 대안 보여줘", "디자인 옵션", "레이아웃 비교", "몇 가지 대안", "UI brainstorm"
---

# ui-brainstorm Skill

## 실행 흐름

### Step 1: 설계 컨텍스트 확인

- code-planner로부터 전달된 경우: 기능명, 컴포넌트 위치, 설계 제약 사용
- 사용자가 직접 요청한 경우: 현재 작업 중인 기능과 결정이 필요한 UI 요소 파악

### Step 2: UI 디자이너 에이전트 실행

```
Agent tool 호출:
  - subagent_type: "crinity-dev:ui-designer"
  - prompt: |
      아래 기능에 대한 UI 옵션 HTML 목업을 생성하고 브라우저에서 프리뷰하라.
      기능명: [기능명]
      결정 필요 UI 컴포넌트: [컴포넌트 목록]
      제약 사항: [제약]
      참고 파일: [경로 목록]
  - description: "UI 목업 생성"
```

에이전트가 HTML 목업 생성 + 브라우저 프리뷰를 수행한다.

### Step 3: 사용자 선택 대기

⏸ 사용자가 채팅에서 번호 입력 ("1번", "2번" 등)

### Step 4: 결과 반환

선택된 옵션 번호, 제목, 핵심 사양을 구조화하여 반환한다:
- code-planner 호출인 경우: 계획의 "설계 결정 사항" 섹션에 기록
- task.md 생성 대상인 경우: UI Design Decisions 테이블에 기록

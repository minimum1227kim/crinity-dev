---
name: code-reviewer
description: >
  코드 리뷰 스킬. Git 변경 내역 기반으로 컨벤션 준수 여부, 보안 취약점, 아키텍처 규칙 위반을 검사한다.
  코드를 작성하거나 수정한 직후, 기능 개발 완료 후 검증 단계, PR 생성 전에는 반드시 이 스킬을 사용해야 한다.
  코드 검증, 검토, 확인 요청이 있을 때도 항상 이 스킬로 처리한다.
  트리거 키워드: "코드 리뷰", "code review", "리뷰해줘", "검토해줘", "확인해줘", "컨벤션 체크",
  "convention check", "코드 검증", "코드 확인", "머지해도 돼?", "PR 올리기 전에", "코드 작성 후 검토"
---

# code-reviewer Skill

## 실행 흐름

### Step 1: 리뷰 에이전트 실행

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-reviewer"
  - prompt: |
      git 변경 내역을 리뷰하라.
      [현재 대화에 계획 텍스트가 있으면 함께 전달하여 계획 대비 구현 검증도 수행]
  - description: "코드 리뷰"
```

### Step 2: 결과 출력

에이전트가 반환한 결과(파일별 위반 테이블 + CRITICAL/HIGH/MEDIUM/LOW 종합)를 사용자에게 전달한다.

## 결과 처리 가이드

| 심각도 | 처리 |
|--------|------|
| CRITICAL | 머지 불가 — 반드시 수정 |
| HIGH | 머지 전 수정 권장 |
| MEDIUM | 가능하면 수정 |
| LOW | 선택적 수정 |

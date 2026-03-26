---
name: code-refactor
description: >
  코드 리팩토링 스킬. 변경된 파일의 컨벤션 위반 수정,
  중복 코드 제거, 성능 최적화를 수행한다. 기능 변경 없이 코드 품질만 개선한다.
  개발 완료 후 자동 실행 또는 명시적 리팩토링 요청 시 사용한다.
  트리거 키워드: "리팩토링", "코드 개선", "refactor", "정리해줘", "컨벤션 맞춰줘"
---

# code-refactor Skill

## 실행 흐름

### Step 1: 리팩토링 에이전트 실행

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-refactorer"
  - prompt: "git diff 기반 변경 파일의 컨벤션 위반 수정, 중복 코드 제거, 성능 최적화를 수행하라. 기능 변경 없이 품질만 개선."
  - description: "코드 품질 개선"
```

### Step 2: 결과 출력

에이전트가 반환한 결과(개선 내역 Before/After + 수동 처리 필요 항목)를 사용자에게 전달한다.

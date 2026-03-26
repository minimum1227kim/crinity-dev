---
name: code-verify
description: >
  빌드/테스트 검증 스킬. 빌드, 테스트, lint를 실행하고 실패 시 원인 분석 및 수정을 수행한다.
  개발 완료 후 또는 명시적 빌드/테스트 요청 시 사용한다.
  트리거 키워드: "빌드해줘", "테스트 돌려줘", "lint 확인해줘", "build", "test", "검증해줘"
---

# code-verify Skill

## 실행 흐름

### Step 1: 검증 에이전트 실행

```
Agent tool 호출:
  - subagent_type: "crinity-dev:code-verifier"
  - prompt: "변경 모듈의 빌드, 테스트, lint를 검증하라. 실패 시 내부에서 최대 3회 수정 후 재시도."
  - description: "빌드/테스트 검증"
```

### Step 2: 결과 출력

에이전트가 반환한 결과(PASS/FAIL 테이블 + 수정 내역 + 미해결 사항)를 사용자에게 전달한다.

## 결과 처리 가이드

| 결과 | 처리 |
|------|------|
| 전체 PASS | 완료 |
| FAIL 자동 수정됨 | 재검증 확인 |
| FAIL 수동 필요 | 사용자에게 원인 보고 |

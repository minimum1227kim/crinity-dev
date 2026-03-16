---
name: plugin-manager
description: >
  플러그인 시스템(CLAUDE.md, agents, skills, rules) 간 일관성을 검증한다.
  교차 참조 무결성, 네이밍, 역할 분리, 계약 일관성, SSOT 위반을 탐지하고 리포트한다.
  에이전트 없이 인라인 실행한다. 읽기 전용 검증이며, 수정은 사용자 승인 후에만 수행한다.
  트리거 키워드: "플러그인 검증", "시스템 검증", "일관성 검사", "plugin check", "plugin validate"
---

# plugin-manager Skill

트리거 키워드: "플러그인 검증", "시스템 검증", "일관성 검사", "plugin check", "plugin validate"

## 목적

Skill/Agent/Rules/CLAUDE.md 4개 레이어 간 일관성을 자동 검증한다.
수동 리뷰에서 반복 발견되는 다음 유형의 이슈를 탐지한다:

- 유령 참조 (존재하지 않는 파일/스텝 참조)
- 역할 위반 (Agent에 오케스트레이션, Skill에 구현 로직)
- SSOT 위반 (동일 정보의 이중 정의)
- 네이밍 불일치 (frontmatter name ≠ 파일명 ≠ 테이블)
- 설명 미갱신 (이름/역할 변경 후 description stale)

---

## 실행 흐름

### Step 1: 인벤토리 수집

4개 레이어의 파일 목록과 메타데이터를 수집한다:

| 레이어 | 수집 대상 | 수집 항목 |
|--------|---------|---------|
| CLAUDE.md | 프로젝트 루트 `CLAUDE.md` | Agent Workflow 섹션, 필수 섹션 존재 여부 |
| Agents | `.claude/agents/*.md` | frontmatter (name, description, tools, model), 본문 Step 목록 |
| Skills | `.claude/skills/*/SKILL.md` | frontmatter (name, description), 위임 에이전트, 참조하는 에이전트 Step |
| Rules | `.claude/rules/*.md` | 파일명 목록 |

---

### Step 2: 참조 무결성 검증 (PM-R)

| ID | 검사 | 심각도 |
|----|------|--------|
| PM-R01 | CLAUDE.md Agent Workflow에서 참조하는 에이전트가 `.claude/agents/`에 실제 파일로 존재하는가 | CRITICAL |
| PM-R02 | `.claude/agents/`에 있는 에이전트 파일이 CLAUDE.md Agent Workflow에서 참조되고 있는가 | HIGH |
| PM-R03 | Skill이 위임하는 에이전트가 `.claude/agents/`에 실제 파일로 존재하는가 | CRITICAL |
| PM-R04 | Skill이 참조하는 에이전트 출력 섹션(예: "변경 규모" 섹션)이 에이전트 출력 형식에 정의되어 있는가 | HIGH |
| PM-R05 | Agent 본문에서 참조하는 rules 파일이 `.claude/rules/`에 실제 존재하는가 | HIGH |

---

### Step 3: 네이밍 일관성 검증 (PM-N)

| ID | 검사 | 심각도 |
|----|------|--------|
| PM-N01 | 에이전트 frontmatter `name`과 파일명(`{name}.md`)이 일치하는가 | HIGH |
| PM-N02 | 스킬 frontmatter `name`과 디렉토리명이 일치하는가 | HIGH |
| PM-N03 | CLAUDE.md Agent Workflow에서 사용하는 에이전트명과 해당 파일의 frontmatter `name`이 일치하는가 | MEDIUM |

---

### Step 4: 역할 분리 검증 (PM-S)

| ID | 검사 | 심각도 |
|----|------|--------|
| PM-S01 | Agent 본문에 다른 에이전트를 실행/호출하는 지시가 있는가 (오케스트레이션 침범) | HIGH |
| PM-S02 | Agent 본문에 태스크 분해, 에이전트 배정 로직이 있는가 (Skill 역할 침범) | HIGH |
| PM-S03 | Skill 본문에 코드 작성, 파일 생성 등 구현 로직이 있는가 (Agent 역할 침범) — 인라인 실행 스킬 제외 | MEDIUM |
| PM-S04 | Rules 파일에 실행 절차, 워크플로우 지시가 있는가 (Skill/Agent 역할 침범) | MEDIUM |

**예외**: `task-manager`, `plugin-manager` 등 인라인 실행 스킬은 PM-S03에서 제외한다.

**탐지 키워드**:
- PM-S01: "에이전트 실행", "에이전트를 호출", "agent 실행", "→ [", "위임"
- PM-S02: "태스크 분해", "에이전트 배정", "task decomposition", "assign agent"
- PM-S03: "파일 생성", "코드 작성", "Write", "Edit" (인라인 실행 스킬 제외)
- PM-S04: "실행한다", "호출한다", "→" (절차 흐름), "Step N:"

---

### Step 5: 계약 일관성 검증 (PM-D)

| ID | 검사 | 심각도 |
|----|------|--------|
| PM-D01 | Skill frontmatter `description`과 실제 본문 동작이 의미적으로 일치하는가 | MEDIUM |
| PM-D02 | Agent frontmatter `tools`에 선언된 도구와 본문에서 실제 사용하는 도구가 일치하는가 | HIGH |
| PM-D03 | Skill이 에이전트 출력을 소비하는 경우, 출력 형식(섹션명, 테이블 구조)이 계약과 일치하는가 | HIGH |

---

### Step 6: SSOT 검증 (PM-O)

| ID | 검사 | 심각도 |
|----|------|--------|
| PM-O01 | 동일 threshold/설정값이 2개 이상 파일에 하드코딩되어 있는가 | HIGH |
| PM-O02 | session-start.sh에서 체크하는 rules 파일 목록과 `.claude/rules/`의 실제 파일이 일치하는가 | MEDIUM |
| PM-O03 | Agent 본문의 "필수 선행 읽기" 섹션에 나열된 rules 파일이 실제 존재하는가 | MEDIUM |

**PM-O01 탐지 방법**: 숫자+단위가 포함된 threshold 패턴을 검색하고, 동일 값이 2개 이상 파일에서 발견되면 위반으로 표시한다. SSOT 참조 문구("~를 따른다", "SSOT:", "참조")가 있는 경우는 제외.

---

### Step 7: 리포트 출력

검증 결과를 심각도순으로 정리하여 출력한다:

```
## 플러그인 시스템 검증 리포트

검증 일시: {YYYY-MM-DD HH:mm}
검증 범위: CLAUDE.md, agents {N}개, skills {N}개, rules {N}개

### 요약

| 심각도 | 건수 |
|--------|------|
| CRITICAL | {N} |
| HIGH | {N} |
| MEDIUM | {N} |
| LOW | {N} |

### 위반 목록

| # | ID | 심각도 | 대상 파일 | 위반 내용 | 권장 조치 |
|---|-----|--------|---------|---------|---------|
| 1 | PM-R01 | CRITICAL | CLAUDE.md | ... | ... |

### 조치 안내

- CRITICAL: 즉시 수정 필요. 승인 시 자동 수정을 진행합니다.
- HIGH: 수정 권장. 수정 여부를 선택해 주세요.
- MEDIUM/LOW: 참고 사항입니다.
```

---

## 결과 처리

| 심각도 | 처리 |
|--------|------|
| CRITICAL | 수정 필요 — 사용자 승인 후 수정 수행 |
| HIGH | 수정 권장 — 사용자 판단 요청 |
| MEDIUM | 목록만 출력 |
| LOW | 목록만 출력 |

수정 수행 시 변경 내용을 diff 형태로 제시하고 사용자 승인을 받은 후에만 적용한다.

---

## 주의사항

- **읽기 전용 검증**: 검증 단계에서는 어떤 파일도 수정하지 않는다
- **인라인 실행**: 전용 에이전트 없이 스킬이 직접 실행한다
- **의미적 판단**: PM-D01(역할 설명 일치), PM-S01~S04(역할 침범 탐지)는 키워드 기반 + 문맥 판단이 필요하다. 확실하지 않은 경우 MEDIUM으로 분류하고 사용자에게 확인을 요청한다

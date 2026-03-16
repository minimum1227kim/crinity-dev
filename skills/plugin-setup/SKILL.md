---
name: plugin-setup
description: >
  에이전트/스킬 플러그인 시스템의 초기 환경을 구성한다.
  CLAUDE.md와 .claude/rules/*.md 파일이 없거나 필수 섹션이 누락된 경우 생성·보완한다.
  rules 파일은 누락분만 생성하고, CLAUDE.md는 필수 섹션이 모두 포함되도록 업데이트한다.
  플러그인 최초 적용 시 또는 session-start 훅 경고 시 사용한다.
  트리거 키워드: "초기 설정", "셋업", "setup", "플러그인 설정", "설정 파일 생성", "rule 생성", "rules 만들어줘"
---

# plugin-setup Skill

트리거 키워드: "초기 설정", "셋업", "setup", "플러그인 설정", "설정 파일 생성", "rule 생성", "rules 만들어줘"

## 실행 흐름

### Step 0: 대상 파일 결정 (스킬이 직접 수행)

다음 파일들의 상태를 확인한다:

| 파일 | 경로 | 처리 방식 |
|------|------|---------|
| 프로젝트 가이드 | `CLAUDE.md` | 없으면 생성 / 있으면 필수 섹션 누락 여부 확인 |
| 아키텍처 규칙 | `.claude/rules/architecture.md` | 없으면 생성 / 있으면 스킵 |
| 백엔드 규칙 | `.claude/rules/backend-rules.md` | 없으면 생성 / 있으면 스킵 |
| 프론트엔드 규칙 | `.claude/rules/frontend-rules.md` | 없으면 생성 / 있으면 스킵 |
| 빌드 명령어 | `.claude/rules/build-commands.md` | 없으면 생성 / 있으면 스킵 |
| UI 규칙 | `.claude/rules/frontend-ui.md` | 없으면 생성 / 있으면 스킵 |
| 금지 규칙 | `.claude/rules/prohibitions.md` | 없으면 생성 / 있으면 스킵 |
| 리뷰 체크리스트 | `.claude/rules/review-checklist.md` | 없으면 생성 / 있으면 스킵 |

**CLAUDE.md 필수 섹션** (플러그인 동작에 필요): `## Project Overview`, `## Agent Workflow`, `## Code Deletion Policy`, `## Memory Storage Policy`

> Agents/Skills 테이블, Rule Documents, Build Commands는 CLAUDE.md에 포함하지 않는다 (각 파일의 frontmatter/본문에서 관리).

**처리 결정**:
- rules 파일 모두 존재 + CLAUDE.md 모든 필수 섹션 존재 → "모든 설정이 완료되어 있습니다." 출력 후 종료
- 누락 rules 파일 있거나 CLAUDE.md 필수 섹션 누락 → 작업 목록 출력 후 Step 1로 진행

---

### Step 1: `plugin-setup` 에이전트 실행

작업 목록(누락 rules 파일, CLAUDE.md 누락/불완전 섹션)을 전달한다. 에이전트는 다음을 수행한다:

1. 언어 / 빌드 시스템 / 프레임워크 자동 감지
2. 감지 결과에 맞는 분석 전략으로 코드베이스 역산
3. 각 누락 rules 파일 생성 (기존 rules 파일 불변)
4. CLAUDE.md가 없으면 신규 생성 / 있으면 필수 섹션이 모두 포함되도록 업데이트

---

### Step 2: 결과 확인 + 사용자 안내

에이전트 완료 후 다음을 출력한다:

- 감지된 기술 스택 요약 (언어, 빌드 시스템, 프레임워크, 모듈 수)
- 생성된 파일별 주요 추출 내용
- 수동 확인 권장 항목 (샘플 부족 또는 패턴 혼재로 자동 감지 불가한 부분)
- `.claude/rules/` 디렉토리를 git 커밋하도록 안내

> 생성된 파일은 실제 코드 샘플 역산 기반입니다.
> 샘플 범위 밖 예외 케이스나 팀 컨벤션과 다른 부분은 직접 수정하세요.

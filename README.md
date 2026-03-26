# crinity-dev — Claude Code Plugin

개발 워크플로우 자동화 플러그인.
9개 에이전트와 10개 스킬로 구성된 코드 계획-개발-리뷰-테스트 파이프라인을 제공한다.

**프로젝트 비종속**: 어떤 프로젝트에도 설치 가능. `/plugin-setup`이 코드베이스를 분석하여 프로젝트별 rules 파일을 자동 생성한다.

---

## 설치

### 방법 1: 마켓플레이스 등록 후 설치 (권장)

```bash
# Step 1: 마켓플레이스 등록
claude plugin marketplace add https://github.com/minimum1227kim/crinity-dev.git

# Step 2: 플러그인 설치
#  로컬 범위 (현재 프로젝트 디렉토리에 설치)
claude plugin install crinity-dev -s local

#  프로젝트 범위
claude plugin install crinity-dev -s project

#  글로벌 범위
claude plugin install crinity-dev

# 설치 확인
claude plugin list
```

### 방법 2: 세션 단위 로딩 (테스트용)

```bash
claude --plugin-dir /path/to/crinity-dev
```

### 설치 확인

Claude Code 실행 시 SessionStart 훅이 자동으로 환경을 점검한다:

```
[crinity-dev] Environment check passed. All required project files found.
```

누락 파일이 있으면 경고가 출력된다. `/plugin-setup`을 실행하여 자동 생성할 수 있다.

### 업데이트 / 제거

```bash
claude plugin update crinity-dev
claude plugin uninstall crinity-dev
```

---

## 초기 설정

설치 후 반드시 `/plugin-setup`을 실행한다:

1. 코드베이스의 언어, 프레임워크, 빌드 시스템을 자동 감지
2. 프로젝트별 rules 파일(`.claude/rules/*.md`) 생성
3. CLAUDE.md 생성 또는 필수 섹션 보완
4. **플러그인 참조 문서를 `.claude/references/`로 복사** (에이전트가 설치 위치와 무관하게 참조 가능)

```bash
# Claude Code 실행 후
/plugin-setup
```

생성된 파일을 검토하고 프로젝트에 맞게 수정한 뒤 git 커밋한다.

---

## 워크플로우

```
Skill = 지휘자 (누가 무엇을 언제) / Agent = 연주자 (어떻게 실행)
```

### 개발 요청 시 자동 실행 흐름

```
사용자 개발 요청
  |
[code-planner]       → 의도 구체화 → 코드베이스 탐색 → 아키텍처 설계
  |                    → session-context.md에 미션 기록
  |
+--- 개발 루프 (최대 3회) ----------------------+
| [developer]  → 백엔드/프론트엔드 개발          |
| [refactorer] → 코드 품질 개선 (첫 회만)        |
| [verifier]   → 빌드/lint + Actionable Feedback |
| [reviewer]   → 코드 리뷰 + 보안 체크           |
|   CRITICAL/HIGH → 루프 반복                    |
|   MEDIUM → 사용자 판단                         |
|   LOW only → 통과                              |
+------------------------------------------------+
  |
  +-- 프론트엔드 변경? → [browser-tester] → UI 테스트
  |
  +-- 3회 실패? → 에스컬레이션 리포트 → 사용자 판단
  |
  완료
```

### 에이전트 간 정보 동기화

모든 에이전트는 `.claude/references/session-context.md`를 통해 세션 단위 컨텍스트를 공유한다:
- **code-planner**: 미션 개요, 아키텍처 결정 사항, Impact Analysis 기록
- **developer**: 이전 에이전트 피드백 확인, 작업 로그 기록
- **verifier**: 구조화된 Actionable Feedback 기록
- **reviewer**: 보안 체크 결과, 통과 기준 판정 기록
- **에스컬레이션**: 3회 실패 시 분석 리포트를 기록하여 사용자에게 판단 근거 제공

---

## 슬래시 커맨드

### 핵심 워크플로우

| 커맨드 | 설명 | 트리거 키워드 |
|--------|------|------------|
| `/code-planner` | 개발 계획 수립 | "개발해줘", "만들어줘", "추가해줘" |
| `/code-developer` | 코드 작성 (계획 수립 후) | "코드 작성 시작", "개발 시작" |
| `/code-reviewer` | 코드 리뷰 | "리뷰해줘", "코드 확인", "PR 올리기 전에" |
| `/code-refactor` | 리팩토링 | "리팩토링", "코드 개선", "컨벤션 맞춰줘" |
| `/code-verify` | 빌드/테스트 검증 | "빌드해줘", "테스트 돌려줘" |
| `/code-tester` | 브라우저 UI 테스트 | "브라우저 테스트", "UI 테스트" |

### 도구

| 커맨드 | 설명 | 트리거 키워드 |
|--------|------|------------|
| `/ui-brainstorm` | UI 설계 목업 비교 | "UI 대안 보여줘", "디자인 옵션" |
| `/task-manager` | 태스크 진행 관리 | "진행 상황", "task list" |

### 관리

| 커맨드 | 설명 | 트리거 키워드 |
|--------|------|------------|
| `/plugin-setup` | 프로젝트 rules + references 자동 생성 | "초기 설정", "셋업" |
| `/plugin-manager` | 플러그인 일관성 검증 | "플러그인 검증", "plugin check" |

---

## 에이전트

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| `code-planner` | opus | 코드베이스 탐색 + 아키텍처 설계 + Impact Analysis |
| `backend-developer` | sonnet | 전 계층 백엔드 개발 (클린코드 원칙 내장) |
| `frontend-developer` | sonnet | 프론트엔드 개발 (클린코드 원칙 내장) |
| `ui-designer` | sonnet | HTML 목업 생성 |
| `code-refactorer` | sonnet | 코드 품질 개선 (기능 변경 없음) |
| `code-verifier` | sonnet | 빌드/테스트/lint + Actionable Feedback |
| `code-reviewer` | sonnet | 컨벤션/보안/아키텍처 리뷰 |
| `browser-tester` | sonnet | 브라우저 UI 기능 테스트 |
| `plugin-setup` | opus | 코드베이스 분석 → rules + references 자동 생성 |

---

## 디렉토리 구조

```
crinity-dev/
├── .claude-plugin/
│   ├── plugin.json          ← 플러그인 매니페스트
│   └── marketplace.json     ← 마켓플레이스 카탈로그
├── hooks/
│   ├── hooks.json           ← 훅 등록 (SessionStart)
│   └── session-start.sh     ← 환경 점검 (rules + references)
├── agents/                  ← 9개 에이전트 정의
│   ├── code-planner.md
│   ├── backend-developer.md
│   ├── frontend-developer.md
│   ├── ui-designer.md
│   ├── code-refactorer.md
│   ├── code-verifier.md
│   ├── code-reviewer.md
│   ├── browser-tester.md
│   └── plugin-setup.md
├── skills/                  ← 10개 스킬 정의
│   ├── code-planner/
│   ├── code-developer/
│   ├── code-refactor/
│   ├── code-reviewer/
│   ├── code-verify/
│   ├── code-tester/
│   ├── ui-brainstorm/
│   ├── task-manager/
│   ├── plugin-setup/
│   └── plugin-manager/
├── references/              ← 에이전트 참조 문서 (plugin-setup이 프로젝트로 복사)
│   ├── planner-output-format.md
│   ├── plugin-setup-detection.md
│   ├── session-context.md
│   ├── ui-options-template.html
│   ├── playwright-cli.md
│   └── playwright-cli/
├── .gitignore
└── README.md
```

### 프로젝트에 생성되는 파일

`/plugin-setup` 실행 후 프로젝트에 다음 구조가 생성된다:

```
{project}/
├── CLAUDE.md                        ← 프로젝트 개요 + 워크플로우
├── .claude/
│   ├── rules/                       ← 프로젝트별 규칙 (코드베이스 역산)
│   │   ├── architecture.md
│   │   ├── backend-rules.md
│   │   ├── frontend-rules.md
│   │   ├── frontend-ui.md
│   │   ├── build-commands.md
│   │   ├── prohibitions.md
│   │   └── review-checklist.md
│   └── references/                  ← 에이전트 참조 문서 (플러그인에서 복사)
│       ├── planner-output-format.md
│       ├── session-context.md
│       ├── plugin-setup-detection.md
│       ├── ui-options-template.html
│       ├── playwright-cli.md
│       └── playwright-cli/
```

---

## 이식성 설계

### 에이전트 경로 규약

에이전트가 참조하는 문서는 **프로젝트 레벨 경로** (`.claude/references/`)를 사용한다:
- 플러그인 설치 위치와 무관하게 동일 경로에서 접근 가능
- `/plugin-setup`이 플러그인 내부 references를 프로젝트로 복사하는 역할 담당

### 관심사 분리

| 위치 | 역할 | 관리 주체 |
|------|------|---------|
| **플러그인** (agents/, skills/) | 실행 로직 | `claude plugin update` |
| **프로젝트** (.claude/rules/) | 프로젝트별 규칙 | 개발자가 직접 수정 |
| **프로젝트** (.claude/references/) | 참조 문서 | plugin-setup이 복사, 필요 시 개발자 수정 |
| **CLAUDE.md** | 워크플로우 정의 | plugin-setup이 생성, 개발자가 커스텀 |

---

## 권장 설정

### Agent Teams 활성화

```json
// .claude/settings.json 또는 ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## 커스터마이징

### 다른 프로젝트에 적용하기

1. 플러그인 설치: `claude plugin install crinity-dev -s local`
2. `/plugin-setup` 실행 → rules + references 자동 생성
3. 생성된 파일 검토 및 프로젝트 맞춤 수정
4. git 커밋

### 에이전트/스킬 추가

- 에이전트: `agents/{name}.md` 파일 생성 (YAML frontmatter 필수)
- 스킬: `skills/{name}/SKILL.md` 파일 생성

### 검증

`/plugin-manager` 실행 → 에이전트/스킬/룰 간 참조 무결성, 네이밍 일관성, 역할 분리 자동 검증.

---

## 라이선스

MIT

# crinity-dev — Claude Code Plugin

Crinity Total Suite 개발 워크플로우 플러그인.
9개 에이전트와 11개 스킬로 구성된 개발 자동화 파이프라인을 제공한다.

---

## 설치

### 방법 1: 마켓플레이스 등록 후 설치 (권장)

Claude Code는 **마켓플레이스** 시스템을 통해 플러그인을 관리한다.
이 레포를 마켓플레이스로 등록하면 `claude plugin install`로 설치할 수 있다.

```bash
# Step 1: 이 레포를 마켓플레이스로 등록
claude plugin marketplace add https://github.com/minimum1227kim/crinity-dev.git

# Step 2: 플러그인 설치
#  2-a : 글로벌 설치
claude plugin install crinity-dev

#  2-b : project 범위 (현재 프로젝트에서만 사용)
claude plugin install crinity-dev -s project

#  2-c : local 범위 (현재 프로젝트 디렉토리에 설치 및 사용)
claude plugin install crinity-dev -s local

# 설치 확인
claude plugin list
```


```

### 방법 2: 세션 단위 로딩 (테스트용)

설치 없이 현재 세션에서만 플러그인을 로드한다:

```bash
# 로컬 디렉토리에 파일 업로드 후 직접 로드
claude --plugin-dir /path/to/crinity-dev
```


### 설치 확인

Claude Code를 실행하면 SessionStart 훅이 자동으로 환경을 점검한다:

```
[crinity-dev] Environment check passed. All required project files found.
```

누락 파일이 있으면 경고가 출력된다. `/plugin-setup`을 실행하여 자동 생성할 수 있다.

### 업데이트

```bash
claude plugin update crinity-dev
```

### 제거

```bash
claude plugin uninstall crinity-dev
# 마켓플레이스도 제거하려면:
claude plugin marketplace remove crinity-dev
```

---

## 사전 요구사항

이 플러그인은 프로젝트 저장소에 다음 파일들이 있어야 정상 동작한다:

| 파일 | 설명 |
|------|------|
| `CLAUDE.md` | 프로젝트 진입점 (워크플로우, 개요) |
| `.claude/rules/architecture.md` | 아키텍처 규칙 |
| `.claude/rules/backend-rules.md` | 백엔드 개발 규칙 |
| `.claude/rules/frontend-rules.md` | 프론트엔드 개발 규칙 |
| `.claude/rules/frontend-ui.md` | UI 레이아웃/컴포넌트 규칙 |
| `.claude/rules/build-commands.md` | 빌드/테스트/lint 명령어 |
| `.claude/rules/prohibitions.md` | 금지 규칙 (보안/컨벤션) |
| `.claude/rules/review-checklist.md` | 코드 리뷰 체크리스트 |

> 파일이 없는 경우 `/plugin-setup`을 실행하면 코드베이스를 분석하여 자동 생성한다.

---

## 워크플로우

```
Skill = 지휘자 (누가 무엇을 언제) / Agent = 연주자 (어떻게 실행)
```

### 개발 요청 시 자동 실행 흐름

```
사용자 개발 요청
  |
[code-planner]       -> 의도 구체화 -> 코드베이스 탐색 -> 아키텍처 설계
  |
+--- 개발 루프 (최대 3회) ---+
| [developer]  -> 백엔드/프론트엔드 개발   |
| [refactorer] -> 코드 품질 개선 (첫 회만) |
| [verifier]   -> 빌드/lint 검증          |
| [reviewer]   -> 코드 리뷰              |
|   CRITICAL/HIGH -> 루프 반복            |
|   LOW only -> 통과                     |
+----------------------------------------+
  |
  +-- 프론트엔드 변경? --> [browser-tester] -> UI 테스트
  |
  완료
```

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
| `/playwright-cli` | 브라우저 자동화 | 웹 테스트, 스크린샷 |

### 관리

| 커맨드 | 설명 | 트리거 키워드 |
|--------|------|------------|
| `/plugin-setup` | 프로젝트 rules 파일 자동 생성 | "초기 설정", "셋업", "rules 만들어줘" |
| `/plugin-manager` | 플러그인 일관성 검증 | "플러그인 검증", "plugin check" |

---

## 에이전트

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| `code-planner` | opus | 코드베이스 탐색 + 아키텍처 설계 |
| `backend-developer` | sonnet | Java/Spring Boot 전 계층 개발 |
| `frontend-developer` | sonnet | Vue 컴포넌트, Store, i18n 개발 |
| `ui-designer` | sonnet | Vuetify 2 HTML 목업 생성 |
| `code-refactorer` | sonnet | 코드 품질 개선 (기능 변경 없음) |
| `code-verifier` | sonnet | 빌드/테스트/lint 실행 + 실패 분석 |
| `code-reviewer` | sonnet | 컨벤션/보안/아키텍처 리뷰 |
| `browser-tester` | sonnet | 브라우저 UI 기능 테스트 |
| `plugin-setup` | opus | 코드베이스 분석 -> rules 파일 자동 생성 |

---

## 디렉토리 구조

```
crinity-dev/
├── .claude-plugin/
│   ├── plugin.json          <- 플러그인 매니페스트
│   └── marketplace.json     <- 마켓플레이스 카탈로그
├── hooks/
│   ├── hooks.json           <- 훅 등록 (SessionStart)
│   └── session-start.sh     <- 환경 점검 스크립트
├── agents/                  <- 9개 에이전트 정의
│   ├── code-planner.md
│   ├── backend-developer.md
│   ├── frontend-developer.md
│   ├── ui-designer.md
│   ├── code-refactorer.md
│   ├── code-verifier.md
│   ├── code-reviewer.md
│   ├── browser-tester.md
│   └── plugin-setup.md
├── skills/                  <- 11개 스킬 정의
│   ├── code-planner/
│   ├── code-developer/
│   ├── code-refactor/
│   ├── code-reviewer/
│   ├── code-verify/
│   ├── code-tester/
│   ├── ui-brainstorm/
│   ├── task-manager/
│   ├── plugin-setup/
│   ├── plugin-manager/
│   └── playwright-cli/
├── .gitignore
└── README.md
```

---

## 커스터마이징

### 다른 프로젝트에 적용하기

1. 플러그인을 설치한다 (위 설치 섹션 참조)
2. Claude Code에서 `/plugin-setup`을 실행한다
3. 플러그인이 코드베이스를 자동 분석하여 `CLAUDE.md`와 `.claude/rules/*.md` 파일을 생성한다
4. 생성된 파일을 검토하고 프로젝트에 맞게 수정한다
5. git에 커밋한다

### 에이전트/스킬 추가

- 에이전트: `.claude/agents/{name}.md` 파일 생성 (YAML frontmatter 필수)
- 스킬: `.claude/skills/{name}/SKILL.md` 파일 생성

### 검증

`/plugin-manager`를 실행하면 에이전트/스킬/룰 간 참조 무결성, 네이밍 일관성, 역할 분리를 자동 검증한다.

---

## 라이선스

MIT

# Plugin Setup — 빌드 시스템별 분석 전략

> plugin-setup 에이전트가 Phase 0 감지 결과에 따라 해당 Phase를 Read하여 실행한다.

---

## Phase 1: 빌드 시스템별 프로젝트 구조 분석

### Phase 1-A: Gradle 멀티모듈

```bash
cat settings.gradle          # 모듈 목록 전체
cat build.gradle             # Spring Boot 버전, Java 버전
# Kotlin인 경우
cat build.gradle.kts 2>/dev/null
```

추출 목표:
- `rootProject.name` → 프로젝트명
- `include '...'` 목록 → 서브모듈 열거
- `org.springframework.boot` 버전 → 백엔드 프레임워크 버전
- `sourceCompatibility` / `jvmTarget` → 언어 버전
- 모듈명 패턴 감지: `{prefix}-{domain}-{layer}` 또는 `{feature}-service` 등

```bash
# 모듈 패턴 자동 감지
cat settings.gradle | grep "include" | sed "s/.*'//;s/'.*$//" | head -20
```

### Phase 1-B: 단일 모듈 (Gradle/Maven)

```bash
# 패키지 최상위 구조 파악
find src/main -type d -not -path "*build*" | head -20

# 레이어 디렉토리명 감지 (entity vs model vs domain 등)
find src/main -type d | grep -E "entity|model|domain|repository|dao|service|controller|handler|usecase|adapter" | head -15
```

→ 실제 발견한 디렉토리명으로 이후 탐색. 가정하지 않는다.

### Phase 1-C: Maven 멀티모듈

```bash
cat pom.xml | grep -E "<groupId>|<artifactId>|<version>|<module>"
find . -name "pom.xml" -maxdepth 3 | head -10
```

### Phase 1-D: JS/TS 전용

```bash
cat package.json
ls src/ 2>/dev/null || ls app/ 2>/dev/null || ls pages/ 2>/dev/null || ls lib/ 2>/dev/null
cat tsconfig.json 2>/dev/null | head -20
```

---

## Phase 2: 백엔드 코드 역산 (언어별)

해당 파일 생성이 필요한 경우에만 수행. 백엔드가 없으면 스킵.

### Phase 2-1: 레이어 구조 탐색

Phase 1에서 감지한 디렉토리명으로 실제 파일 탐색:

```bash
# 감지된 레이어명으로 파일 목록 확인 (예시 - 실제 감지값으로 대체)
find . -name "*.java" -path "*/{detected_entity_dir}/*" -not -path "*/build/*" | head -10
find . -name "*.java" -path "*/{detected_service_dir}/*" -not -path "*/build/*" | head -10
```

**2개 이상 도메인/모듈에서 각 레이어 파일 2~3개 Read.**
→ 3개 중 2개 이상 동일 패턴 → 규칙 채택
→ 패턴 혼재 → 각 패턴과 사용 모듈명 기재 + `<!-- TODO -->`

### Phase 2-2: Java/Kotlin 추출 항목

**데이터 모델 레이어** (Entity/Model/Document 등):
- ID 전략: `@GeneratedValue(strategy=AUTO/IDENTITY/SEQUENCE/UUID)` 또는 수동 할당
- 클래스 상속/구현: `implements`, `extends`, `@MappedSuperclass` 여부
- 어노테이션 조합: `@Entity`/`@Document`/`@Table`/`@Data`/`@Builder` 등
- 네이밍 접두사/접미사 패턴
- 타임스탬프 타입: `Long` ms, `LocalDateTime`, `Instant`, `ZonedDateTime`
- 멀티테넌시 키: `companyId`, `tenantId`, `organizationId` 등 존재 여부

**Repository/DAO 레이어**:
- 상속 타입: `JpaRepository`, `MongoRepository`, `CrudRepository`, `@Mapper`(MyBatis) 등
- 멀티테넌시 필터: 쿼리에 테넌시 키 포함 여부
- 파라미터 바인딩 방식: `@Param`, 위치 파라미터, QueryDSL 등

**Service 레이어**:
- DI 방식: `@RequiredArgsConstructor` + `final`, `@Autowired`, 생성자 주입 수동
- 트랜잭션: `@Transactional(readOnly=true)` 분리 여부

**Controller/Handler 레이어**:
- 인증 파라미터: `@SessionData`, `@AuthenticationPrincipal`, `HttpSession` 등
- 응답 방식: `ResponseEntity`, `@ResponseBody`, GraphQL `@QueryMapping` 등
- API 문서화: `@ApiOperation`(Swagger2), `@Operation`(OpenAPI3), 없음

### Phase 2-3: Python 추출 항목

```bash
find . -name "*.py" -not -path "*__pycache__*" -not -path "*/.venv/*" | head -10
grep -r "FastAPI\|Flask\|Django\|SQLAlchemy\|Pydantic" --include="*.py" | head -5
```

추출: 프레임워크(FastAPI/Flask/Django), ORM(SQLAlchemy/Django ORM/없음), Pydantic 사용 여부

### Phase 2-4: Go 추출 항목

```bash
cat go.mod | grep "^module\|^require"
find . -name "*.go" -not -path "*/vendor/*" | head -10
grep -r "gin\|echo\|fiber\|gorm\|sqlx" --include="*.go" | head -5
```

추출: 웹 프레임워크, ORM/query builder, 프로젝트 레이아웃(Standard Layout 여부)

---

## Phase 3: 프론트엔드 코드 역산 (프레임워크별)

해당 파일 생성이 필요한 경우에만 수행.

### Phase 3-1: 프론트엔드 루트 파악

Phase 0에서 감지한 `package.json` 위치가 각 앱의 루트.
위치가 다를 수 있음: `/frontend/`, `/client/`, `/web/src/frontend/`, `/apps/web/` 등

```bash
# 각 프론트엔드 앱 루트의 src 구조 확인
ls {frontend_root}/src/ 2>/dev/null
```

### Phase 3-2: Vue 2 역산

```bash
find {frontend_root}/src -name "*.vue" -not -path "*/node_modules/*" | head -10
find {frontend_root}/src -name "*.js" -path "*/store/*" | head -5
find {frontend_root}/src -name "vuetify*" -o -name "element*" 2>/dev/null  # UI 라이브러리 감지
```

Read 대상 파일 3개 이상 → 추출:
- Options API 구조 (`data()`, `computed:`, `methods:`)
- Vuex 접근 방식 (`this.$store.dispatch` vs `mapActions`)
- CSS scoping 방식 (`<style scoped>` vs global)
- i18n 사용 여부 (`$t("key")` 패턴)
- UI 컴포넌트 라이브러리 (Vuetify, Element, Ant Design 등)

### Phase 3-3: Vue 3 역산

```bash
find {frontend_root}/src -name "*.vue" | head -8
find {frontend_root}/src -name "*Store.ts" -o -name "*store.ts" | head -5
grep -r "defineStore\|createPinia" {frontend_root}/src --include="*.ts" | head -3
```

추출: `<script setup lang="ts">` 사용 여부, Pinia vs Vuex4, `storeToRefs` 패턴

### Phase 3-4: React 역산

```bash
find {frontend_root}/src -name "*.tsx" -o -name "*.jsx" | head -8
grep -r "useState\|useReducer" {frontend_root}/src --include="*.tsx" | head -5
grep -r "createSlice\|configureStore\|zustand\|recoil\|jotai" {frontend_root}/src --include="*.ts" | head -3
```

추출: 함수형 컴포넌트 100% 여부, 상태관리 라이브러리, Custom Hooks 패턴, CSS-in-JS vs module

### Phase 3-5: 공통 추출 항목

```bash
# i18n 구조
find {frontend_root} -type d -name "locales" -o -name "i18n" -o -name "_locales" 2>/dev/null
ls {i18n_dir}/ 2>/dev/null   # 언어 디렉토리 목록

# API 호출 패턴
find {frontend_root}/src -name "*.api.*" -o -name "*api.*" -o -name "*service.*" | head -5

# 라우터 구조
find {frontend_root}/src -name "router*" -o -name "routes*" | head -3
```

---

## Phase 4: 금지 규칙 코드 증거 수집

```bash
# 의존성 주입 방식 (Java)
grep -r "@Autowired" --include="*.java" -l 2>/dev/null | wc -l
grep -r "@RequiredArgsConstructor" --include="*.java" -l 2>/dev/null | head -3

# 멀티테넌시 키 존재 여부
grep -rn "companyId\|tenantId\|organizationId\|workspaceId" \
  --include="*.java" --include="*.kt" -l 2>/dev/null | head -5

# CSS 색상 하드코딩 현황
grep -rn "color.*#[0-9a-fA-F]\{3,6\}" --include="*.vue" --include="*.tsx" 2>/dev/null | head -5
grep -rn "var(--" --include="*.vue" --include="*.tsx" 2>/dev/null | head -3

# 직접 메시징 브로커 사용 여부
grep -rn "SimpMessagingTemplate\|KafkaTemplate\|RabbitTemplate" \
  --include="*.java" -l 2>/dev/null | head -3

# Entity 직접 반환 여부 (Controller에서)
grep -rn "ResponseEntity<[A-Z][a-z]" --include="*.java" 2>/dev/null | head -5
```

→ 발견한 패턴의 역방향이 금지 규칙, 준수 사례가 권장 패턴
→ 프로젝트에 없는 기술의 금지 규칙은 포함하지 않음

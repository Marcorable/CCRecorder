<!-- marcorable-kit:common:marcorable-github:start -->
# Marcorable 공통 에이전트 문서 — marcorable-github

- 공통 정본은 `agent-common/`이다. `.claude/`, `.agents/`의 문서는 생성물이므로 직접 수정하지 않는다.
- 절차 작업 전에는 해당 스킬을 사용한다. 스킬의 실제 내용은 `agent-common/marcorable-github/skills/`에 있다.
<!-- marcorable-kit:common:marcorable-github:end -->

<!-- marcorable-kit:common:marcorable-tca:start -->
# Marcorable 공통 에이전트 문서 — marcorable-tca

- 공통 정본은 `agent-common/`이다. `.claude/`, `.agents/`의 문서는 생성물이므로 직접 수정하지 않는다.
- 코드 작업 전에는 관련 `agent-common/marcorable-tca/rules/` 문서를 읽고 따른다.
- Codex에서는 `marcorable-tca-rules` 스킬로 같은 코드 규칙을 적용한다.
<!-- marcorable-kit:common:marcorable-tca:end -->

<!-- marcorable-kit:common:marcorable-swiftui:start -->
# Marcorable 공통 에이전트 문서 — marcorable-swiftui

- 공통 정본은 `agent-common/`이다. `.claude/`, `.agents/`의 문서는 생성물이므로 직접 수정하지 않는다.
- 코드 작업 전에는 관련 `agent-common/marcorable-swiftui/rules/` 문서를 읽고 따른다.
- Codex에서는 `marcorable-swiftui-rules` 스킬로 같은 코드 규칙을 적용한다.
- 절차 작업 전에는 해당 스킬을 사용한다. 스킬의 실제 내용은 `agent-common/marcorable-swiftui/skills/`에 있다.
<!-- marcorable-kit:common:marcorable-swiftui:end -->

<!-- marcorable-kit:common:marcorable-swift:start -->
# Marcorable 공통 에이전트 문서 — marcorable-swift

- 공통 정본은 `agent-common/`이다. `.claude/`, `.agents/`의 문서는 생성물이므로 직접 수정하지 않는다.
- 코드 작업 전에는 관련 `agent-common/marcorable-swift/rules/` 문서를 읽고 따른다.
- Codex에서는 `marcorable-swift-rules` 스킬로 같은 코드 규칙을 적용한다.
- 절차 작업 전에는 해당 스킬을 사용한다. 스킬의 실제 내용은 `agent-common/marcorable-swift/skills/`에 있다.
<!-- marcorable-kit:common:marcorable-swift:end -->

# CCRecorder

영어 회화를 녹음해 다시 들으며 모르는 단어와 문장을 기록하는 iOS 앱. v2 는 `CCRecorder/` (SwiftUI + SwiftData), `CasualConversation/` 은 v1 레거시다.

코드 규칙은 `.claude/rules/marcorable-swift/`, `.claude/rules/marcorable-swiftui/`, `.claude/rules/marcorable-tca/`에 있다.

## Code Review Rules

- 리뷰는 한국어로 쓴다
- 녹음·재생 상태 전환(`AudioRecorder`, 화면 Feature)에서 녹음물이 지워지지 않거나 의도치 않게 남는 경로를 우선해서 본다
- 새 화면이 SwiftUI Screen 구조(`.claude/rules/marcorable-swiftui/swiftui/screen-structure.md`)와 TCA Feature 구성(`.claude/rules/marcorable-tca/architecture/feature-composition.md`)을 따르는지 본다. 변경하지 않은 레거시 코드의 규칙 위반은 지적하지 않는다

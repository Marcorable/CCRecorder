# CCRecorder

영어 회화를 녹음해 다시 들으며 모르는 단어와 문장을 기록하는 iOS 앱. v2 는 `CCRecorder/` (SwiftUI + SwiftData), `CasualConversation/` 은 v1 레거시다.

코드 규칙은 `.claude/rules/marcorable-swift/` 에 있다.

## Code Review Rules

- 리뷰는 한국어로 쓴다
- 녹음·재생 상태 전환(`AudioRecorder`, 화면 ViewModel)에서 녹음물이 지워지지 않거나 의도치 않게 남는 경로를 우선해서 본다
- 새 화면이 Screen 패턴(`.claude/rules/marcorable-swift/architecture/screen-pattern.md`)을 따르는지 본다. 변경하지 않은 레거시 코드의 규칙 위반은 지적하지 않는다

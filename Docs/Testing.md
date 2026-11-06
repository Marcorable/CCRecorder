# 테스트 운영

## 테스트 대상

| 실행 단위 | 대상 | 용도 |
| --- | --- | --- |
| `App` | `CCRecorderTests` | 앱 유닛 테스트 |
| `App` | `CCRecorderUITests` | 로컬 UI 테스트 |

UI 테스트는 실행 시간과 시뮬레이터 러너의 안정성을 고려해 Cloud에서 실행하지 않는다. Xcode Cloud 설정은 Tuist workspace와 `CCRecorderTests` 대상으로 전환한다.

## UI 테스트

Tuist가 생성한 workspace에서 `App` 스킴의 `CCRecorderUITests`를 선택하거나 다음 명령을 실행한다.

```sh
xcodebuild test \
  -workspace CCRecorder.xcworkspace \
  -scheme App \
  -testPlan Local-UI \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0'
```

2026년 10월 16일 Xcode 26.2에서 `testNoteTabDoesNotCrash`를 직접 실행한 결과, iOS 18.0과 iOS 26.5에서 각각 통과했다. 기존에 보고된 `SBMainWorkspace`의 `FBSOpenApplicationServiceErrorDomain Code=1`은 재현되지 않았다. 전용 플랜에서 UI 테스트 타깃을 직렬 실행했으므로, 이전 실패는 앱 로직보다는 당시의 시뮬레이터 또는 병렬 테스트 러너 상태와 관련됐을 가능성이 있다. 원인은 확정하지 않는다.

같은 오류가 다시 발생하면 `.xcresult`를 보존하고 다음 순서로 확인한다.

1. `CCRecorderUITests`만 선택됐는지 확인한다.
2. 동일한 시뮬레이터에서 Xcode로 UI 테스트 하나만 직접 실행한다.
3. 시뮬레이터를 재부팅한 뒤 다시 실행한다.
4. 계속 실패하면 새 시뮬레이터에서 실행해 런타임과 기기 상태를 분리한다.

## 마이크 권한이 필요한 테스트

`AudioRecorderTests`는 실제 `AVAudioRecorder`와 마이크 권한에 의존한다. 권한이 없으면 실패시키지 않고 테스트를 건너뛴다.

로컬 시뮬레이터에서는 테스트 전에 권한을 부여할 수 있다.

```sh
xcrun simctl privacy <SIMULATOR_UDID> grant microphone com.pseapplications.CasualConversation
```

Xcode Cloud에서는 다음 이유로 현재 skip 정책을 유지한다.

- 병렬로 생성되는 테스트 시뮬레이터를 사전 스크립트에서 안정적으로 특정하기 어렵다.
- 권한을 부여해도 Cloud의 가상 환경은 실제 마이크 입력을 보장하지 않는다.
- 권한이나 가상 오디오 상태 때문에 제품 코드와 무관한 간헐적 실패가 발생할 수 있다.

파일 생성·삭제, 화면 상태 전환, 재생 제어처럼 하드웨어 입력이 필요 없는 동작은 유닛 테스트로 계속 검증한다.

## 녹음부터 재생까지의 전체 흐름

실제 마이크를 사용하는 `녹음 → 저장 → 목록 → 재생` 흐름은 자동 UI 테스트로 만들지 않는다. UI 러너, 개인정보 권한, 오디오 입력 타이밍에 모두 의존해 CI 회귀 테스트로는 신뢰하기 어렵기 때문이다.

대신 다음 계층으로 나누어 검증한다.

- 자동 테스트: 녹음 상태 전환, 파일 저장·삭제, 대화 저장, 목록 데이터, 재생 제어
- 릴리스 QA: 실기기에서 신규 녹음, 일시정지·재개, 저장, 목록 노출, 재생, 삭제를 한 번의 흐름으로 확인

릴리스 QA에서는 녹음을 취소하거나 저장에 실패했을 때 임시 파일이 남지 않는지, 대화를 삭제했을 때 연결된 녹음 파일도 제거되는지를 함께 확인한다.

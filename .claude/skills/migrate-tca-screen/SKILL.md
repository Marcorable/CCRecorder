---
name: migrate-tca-screen
description: 레거시 SwiftUI 화면 하나를 새 UI·Presentation 경계로 옮기고 TCA Screen·Feature, presentation과 실제 진입 경로를 end-to-end로 적용한다. 화면 이동과 TCA 전환, Detail 진입값을 Domain Entity에서 ID 기반 조회로 바꾸는 요청에 사용한다. MVVM 프로젝트에는 사용하지 않는다.
---

# TCA 화면 마이그레이션

이 스킬은 이동, TCA 구조와 presentation의 원자 스킬을 조합한다.

## 1. 범위 확인

- 화면 파일, 진입 경로와 기존 상태 소유자를 찾는다.
- push, sheet, fullScreenCover, alert와 dismiss 후처리를 정리한다.
- Service·Repository·Usecase와 객체 수명 요구를 확인한다.
- 파일 이동, 상태 구조 변경과 레거시 제거를 구분해 계획한다.

## 2. 원자 스킬 적용

필요한 문서를 순서대로 읽고 적용한다.

1. 화면 위치를 바꿔야 하면 설치된 `agent-common/marcorable-ui/skills/relocate-screen/SKILL.md`
2. 화면을 Feature로 전환하려면 `../apply-tca-screen-pattern/SKILL.md`
3. 화면 내부 presentation이 있으면 `../connect-tca-presentation/SKILL.md`
4. 새 진입 경로가 필요하면 설치된 `agent-common/marcorable-ui/skills/wire-screen-entry/SKILL.md`

`marcorable-ui`는 화면 이동이나 앱 진입 연결이 필요한 단계에서만 사용한다. 팩이 없고 해당 단계가 필요하면 현재 UIKit·SwiftUI 구조를 임의로 추정하지 말고 `marcorable-ui` 설치가 필요한 이유를 알린다. 위치와 진입 경로가 이미 준비됐으면 이 단계들을 건너뛴다.

각 단계 뒤 관련 모듈을 빌드해 이동 문제와 상태 변경 문제를 분리한다.

## 3. Detail 진입값 분리

Navigation route나 presentation state가 수정 가능한 Domain Entity 전체를 받으면 다음을 확인한다.

- Detail이 전달된 스냅샷만 쓰는지, 진입 시점의 최신 원본이 필요한지 구분한다.
- 최신 원본이 필요하거나 Route의 `Hashable` 요구 때문에 Entity가 `Hashable`을 채택했다면 ID 전달을 우선한다.
- Entity가 실제 `Set` 원소나 Dictionary key로 쓰이지 않으면 Navigation을 위해 `Hashable`을 추가하지 않는다. State 비교만 필요하면 `Equatable`로 유지한다.

ID 기반 조회를 선택하면 레이어를 끝까지 연결한다.

1. Repository에 `read(id:) async throws -> Entity?` 단건 조회를 추가한다.
2. Usecase는 `Result<Entity?, DomainError>`로 Repository 오류를 변환한다.
3. TCA Dependency client에 단건 조회 endpoint를 추가한다.
4. Route와 부모 delegate는 Entity 대신 `Entity.ID`를 전달한다.
5. Detail State는 `entityID`, Optional Entity와 로딩 실패 상태를 소유한다.
6. 화면 진입 Action에서 Entity를 조회한 뒤 Entity가 필요한 후속 Effect를 시작한다.
7. 로딩 중, 조회 실패와 삭제되어 `nil`인 상태를 View에 표현한다.

Presentation을 소유한 부모는 dismiss 또는 pop 사건을 감지하고 목록 Feature에 의미 있는 사건을 전달한다. 목록 Feature가 reload 필요 여부를 결정하도록 하며, 부모가 자식의 `.reload` 구현을 직접 호출하지 않는다.

Preview는 ID로 State를 만들고 단건 조회 Dependency가 샘플 Entity를 반환하게 한다. 테스트는 다음 경계를 나눠 검증한다.

- Repository의 단건 조회 성공과 미존재 `nil`
- Usecase의 성공과 Data 오류 변환
- Detail 진입 시 ID 조회와 로딩 실패 상태
- 부모가 dismiss 또는 pop 사건을 목록 Feature에 전달하는 흐름

Repository·Usecase 추가와 Detail 전환은 검토 가능한 별도 커밋으로 나눌 수 있다. Entity 전달을 유지하는 다른 화면이나 관련 없는 Navigation 구조 변경을 같은 커밋에 섞지 않는다.

## 4. 완료 조건

- 화면 상태와 사용자 동작을 `Screen.Root.Feature`가 소유한다.
- child 상태, Effect와 Dependency의 수명 경계가 명시됐다.
- presentation의 생성, dismiss와 부모 후처리가 테스트됐다.
- Detail이 ID로 진입한다면 단건 조회와 로딩 실패 경로가 테스트됐다.
- 기존 사용자 진입 경로와 대표 시나리오가 동작한다.

커밋과 레거시 파일 제거는 요청 범위가 명확할 때만 별도 수행한다.

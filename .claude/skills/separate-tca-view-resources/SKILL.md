---
name: separate-tca-view-resources
description: 기존 TCA Feature에서 상태 전환 조건과 SwiftUI·UIKit 리소스 매핑을 분리한다. Feature가 Asset·Color·Image·Font 같은 UI 타입을 저장하거나 import하고, UI가 리소스 값으로 상태를 추론할 때 사용한다. View 분기 정규화, 컴포넌트 입력 투영, Child Feature 추출과 상태 소유권 이동에는 사용하지 않는다.
---

# TCA UI 리소스 경계 분리

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-tca/rules/architecture/feature-state-ownership.md`
- SwiftUI를 사용한다면 `agent-common/marcorable-swiftui/rules/swiftui/view-resource-boundary.md`

## 입력

- 정리할 TCA Feature와 연결된 UI
- 현재 사용하는 UI 리소스와 리소스 매핑
- 유지해야 할 상태 전환과 Action 조건

## 수행

1. Feature가 import하거나 저장하는 UI 프레임워크·리소스 타입을 찾는다.
2. UI가 Asset 이름, 색상, 이미지 위치 같은 표현 값으로 상태를 추론하는지 확인한다.
3. 순서·선택·노출·활성화·Action 판단에 참여하는 의미만 enum·ID·Bool 같은 프레임워크 중립 값으로 Feature에 남긴다.
4. 원본 상태에서 계산할 수 있는 조건은 별도로 저장하지 않고 파생한다.
5. 중립 값을 최종 UI 리소스로 바꾸는 매핑은 View나 presentation 계층으로 옮긴다.
6. Feature에서 불필요해진 UI import와 리소스 필드를 제거한다.
7. 상태 조건은 TestStore나 상태 단위 테스트로, 리소스 연결은 관련 UI 빌드로 검증한다.

## 제외

- 반복되는 View 분기를 이 작업에서 함께 정규화하지 않는다.
- 공용 컴포넌트용 표시 모델을 만들지 않는다.
- Child Feature를 추출하거나 Source of Truth를 이동하지 않는다.
- UI 동작, Action 의미와 상태 전환을 바꾸지 않는다.
- 상태 판단에 참여하지 않는 장식 리소스를 Feature 상태로 올리지 않는다.

## 완료 조건

- Feature가 UI 프레임워크와 최종 리소스 타입에 의존하지 않는다.
- 상태 조건의 Source of Truth가 하나이고 중복 저장되지 않는다.
- UI 계층이 최종 리소스 선택을 소유한다.
- 관련 상태 테스트와 UI 빌드가 통과한다.

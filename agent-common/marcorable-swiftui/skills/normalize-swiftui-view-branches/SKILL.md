---
name: normalize-swiftui-view-branches
description: 기존 SwiftUI 코드의 if·switch 분기가 같은 View와 modifier 구조를 반복하고 표시 값만 다를 때 하나의 구조로 정규화한다. 상태 소유권 이동, UI 리소스 경계 변경, 컴포넌트 API 설계와 새 화면 구현에는 사용하지 않는다.
---

# SwiftUI View 분기 정규화

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-swiftui/rules/swiftui/view-branch-normalization.md`
- `agent-common/marcorable-swiftui/rules/swiftui/view-local-expression.md`
- `agent-common/marcorable-swiftui/rules/swiftui/view-composition.md`

## 입력

- 반복되는 조건 분기가 있는 SwiftUI View
- 분기를 대표하는 상태
- 유지해야 할 동작과 접근성 의미

## 수행

1. 조건별 View 구조, modifier, Action, 접근성 의미와 생명주기를 비교한다.
2. 레이아웃이나 동작 의미가 다르면 합치지 않고 별도 분기를 유지한다.
3. 구조가 같다면 조건마다 달라지는 최종 표시 값만 식별한다.
4. 한 번 쓰는 단순 값은 사용 위치 가까이 계산한다.
5. 여러 위치에서 함께 쓰이거나 이름이 필요한 값은 작은 UI 입력 값으로 묶는다.
6. 하나의 View 구조에 계산한 표시 값을 주입하고 불필요한 중간 판정을 제거한다.
7. 대표 상태 Preview와 관련 빌드로 결과를 확인한다.

## 제외

- Feature나 Domain의 상태 소유권을 바꾸지 않는다.
- 상태 조건과 UI 리소스의 소유 계층을 옮기지 않는다.
- 공용 컴포넌트 API를 새로 설계하지 않는다.
- 코드 길이를 줄이기 위해 View를 private 함수나 `@ViewBuilder`로 숨기지 않는다.

## 완료 조건

- 의미가 같은 분기만 하나의 View 구조로 합쳐진다.
- Action, 접근성, 생명주기와 레이아웃 의미가 유지된다.
- 조건별 차이는 최종 표시 값으로 드러난다.
- 대표 Preview와 관련 빌드가 통과한다.

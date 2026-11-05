---
name: project-swiftui-component-input
description: 재사용 SwiftUI 컴포넌트가 Domain Entity나 업무 모듈에 직접 의존할 때 필요한 표시 값과 Action만 받는 UI 입력으로 투영한다. 화면 전용 View, 상태 소유권 변경, 리소스 경계 분리와 View 분기 정규화에는 사용하지 않는다.
---

# SwiftUI 컴포넌트 입력 투영

다음 규칙을 먼저 읽는다.

- `agent-common/marcorable-swiftui/rules/swiftui/component-display-input.md`
- `agent-common/marcorable-swiftui/rules/swiftui/view-composition.md`
- `agent-common/marcorable-swiftui/rules/swiftui/ui-layout.md`

## 입력

- 정리할 SwiftUI 컴포넌트와 호출 지점
- 현재 전달하는 Domain 값
- 컴포넌트가 표시하는 값과 실행하는 Action

## 수행

1. 둘 이상의 화면에서 쓰이거나 공용 API로 유지할 컴포넌트인지 확인한다.
2. 화면 전용이라면 별도 표시 모델을 만들지 않고 사용하는 화면 가까이에 둔다.
3. 공용 컴포넌트가 실제로 표시하는 문자열·아이콘·스타일·안정 식별자와 Action만 목록화한다.
4. 필요한 값만 담는 중첩 `ViewModel`, `Content` 같은 UI 전용 입력 타입을 만든다.
5. 상위 화면이 Domain 값을 UI 입력으로 변환하도록 호출 지점을 옮긴다.
6. 컴포넌트에서 Domain import와 업무 정책 판단을 제거한다.
7. 대표 Preview, 호출 지점 테스트와 관련 빌드를 실행한다.

## 제외

- 컴포넌트가 저장, 탐색, 권한이나 업무 규칙을 결정하게 하지 않는다.
- 사용 가능성이 있다는 이유만으로 화면 전용 View를 공용 컴포넌트로 승격하지 않는다.
- Feature의 상태 소유권이나 상태 전환을 바꾸지 않는다.
- 반복되는 화면 분기나 UI 리소스 경계를 함께 정리하지 않는다.

## 완료 조건

- 공용 컴포넌트가 UI 타입과 Action만 입력으로 받는다.
- 호출자가 Domain 값을 표시 입력으로 변환한다.
- 입력 API에 실제로 사용하지 않는 값이나 업무 정책이 없다.
- 대표 Preview와 관련 빌드가 통과한다.

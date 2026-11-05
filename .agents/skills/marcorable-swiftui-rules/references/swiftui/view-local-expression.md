
# SwiftUI 로컬 표현 위치

한 번만 쓰고 사용 위치에서 의도를 바로 이해할 수 있는 표현은 별도 `private` 계산 프로퍼티나 함수로 감싸지 않는다.

- 짧고 중첩되지 않은 조건식
- Action 하나를 보내는 동작 클로저
- 특정 입력 View만 사용하는 `Binding(get:set:)`
- 이름을 붙여도 의미가 늘지 않는 단순 변환

표현이 여러 곳에서 반복되거나 이름이 UI 의미를 더하거나 복잡한 분기를 숨길 때만 추출한다. 단지 `body`가 길다는 이유로 한 번만 쓰는 표현을 파일 아래로 옮기지 않는다.

화면 구조를 가릴 정도의 독립 UI 영역은 함수나 `@ViewBuilder` 계산 프로퍼티가 아니라 `view-composition.md`에 따라 중첩 View 타입으로 나눈다.

`@State`, `@FocusState`, Environment와 Store 상태를 함께 사용하는 계산은 사용하는 View 가까이에 둔다. View 로컬 상태를 상태 컨테이너에 역으로 밀어 넣지 않는다.

## 한 번 쓰는 switch 매핑

enum, Optional처럼 패턴으로 구분하는 상태 하나를 표시 값 하나로 바꾸고 그 결과를 한 번만 사용한다면, 별도 계산 프로퍼티나 함수로 추출하지 않고 사용 위치에 둔다. 호출 인자에 `switch` 표현식을 직접 쓸 수 없을 때는 즉시 실행 클로저로 감싼다.

```swift
.opacity(
    {
        switch phase {
            case .ready:        1
            case .loading:      0.5
            case .failed:       0
        }
    }()
)
```

이 형태는 다음 조건을 모두 만족할 때만 사용한다.

- 하나의 입력 상태만 분기한다
- 각 case가 부수 효과나 추가 처리 없이 값 하나를 반환한다
- 중첩 분기 없이 사용 위치에서 전체 매핑을 바로 이해할 수 있다

같은 매핑을 반복해서 사용하거나 이름이 UI 의미를 더하거나 분기에 계산·부수 효과가 섞이면 가장 가까운 소유 타입의 계산 프로퍼티나 함수로 추출한다. 최종 SwiftUI 리소스의 소유 위치는 `view-resource-boundary.md`, `case` 들여쓰기와 짧은 반환값의 열 정렬은 `agent-common/marcorable-swift/rules/swift/switch-indent.md`를 따른다.


# TCA reducer 분리

가독성만으로도 reducer를 분리할 충분한 이유가 된다. Action이 많아져 최상위 `Reduce`의 흐름을 한눈에 읽기 어렵다면 같은 Feature 안에서 역할별 함수로 분리한다.

이 규칙은 Action enum의 중첩 여부와 독립적으로 적용한다. Action의 의미와 분류는 `action-organization.md`를 따른다.

## 분리 수준

Action 개수나 코드 줄 수로 기계적인 임계값을 정하지 않고 코드를 한눈에 읽고 원하는 처리를 찾을 수 있는지 판단한다.

| 상황 | 선택 |
|---|---|
| 같은 State를 다루지만 최상위 switch가 한눈에 읽히지 않음 | Action 역할별 reducer 함수로 분리 |
| 역할별 함수까지 나눴지만 한 파일이 여전히 길고 탐색하기 어려움 | 같은 Feature의 역할별 extension 파일로 분리 |
| State, View, 생명주기 또는 Effect 취소 범위가 독립됨 | Child Feature와 `Scope`로 분리 |

## 최상위 reducer

`body`는 `@Reducer` 타입 본체에 두고 Child Feature를 `Scope`로 조합한다. 최상위 `Reduce`는 전체 Action 흐름을 보여주는 목차로 유지하고 실제 처리는 역할별 함수에 위임한다.

```swift
@Reducer
struct SearchFeature {
    // State와 Action

    var body: some ReducerOf<Self> {
        Scope(state: \.child, action: \.child) {
            ChildFeature()
        }

        Reduce { state, action in
            switch action {
                case .view(let action):
                    return reduce(into: &state, action: action)

                case .response(let action):
                    return reduce(into: &state, action: action)

                case .child, .delegate:
                    return .none
            }
        }
    }
}

extension SearchFeature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                return loadRows()

            case .queryChanged(let query):
                state.query = query
                return loadRows()

            case .rowTapped(let id):
                return .send(.delegate(.rowSelected(id)))
        }
    }

}
```

- 최상위 Action 분기만을 위한 `coreReduce` 같은 중간 함수는 만들지 않는다
- `private func reduce(into:action: Action)`은 `Reducer` 프로토콜 요구사항과 충돌하므로 만들지 않는다
- `reducePart1`, `reducePart2`처럼 줄 수만 나누지 않는다
- 역할별 함수는 중첩 Action 타입으로 오버로드한 `reduce(into:action:)`를 사용한다
- Action 묶음 하나가 커지면 해당 묶음 안에서도 도메인 의미에 따라 함수를 더 나눈다
- `child`에서 부모가 반응할 사건이 없다면 별도의 `reduceChild`를 만들지 않는다
- `delegate`는 부모가 관찰하는 출력이므로 해당 Feature에서는 보통 `.none`으로 끝낸다
- 여러 reducer의 실행 순서가 동작에 영향을 주지 않도록 최상위 switch에서 한 역할별 함수로 명시적으로 전달한다

## 역할별 reducer

역할별 함수는 자신이 담당하는 Action을 빠짐없이 처리한다.

```swift
extension SearchFeature {

    private func reduce(
        into state: inout State,
        action: Action.View
    ) -> Effect<Action> {
        switch action {
            case .appeared:
                return loadRows()

            case .queryChanged(let query):
                state.query = query
                return loadRows()

            case .rowTapped(let id):
                return .send(.delegate(.rowSelected(id)))
        }
    }

    private func reduce(
        into state: inout State,
        action: Action.Response
    ) -> Effect<Action> {
        switch action {
            case .rowsLoaded(.success(let rows)):
                state.rows = rows
                return .none

            case .rowsLoaded(.failure):
                state.rows = []
                return .none
        }
    }

}
```

## 파일 분리

같은 파일로 충분하면 `private` 함수와 역할별 extension으로 나눈다. 파일 자체가 길거나 원하는 reducer를 찾기 어렵다면 다음처럼 옮긴다.

```text
SearchFeature/
├── SearchFeature.swift
├── SearchFeature + ViewReducer.swift
└── SearchFeature + ResponseReducer.swift
```

다른 파일의 extension으로 옮긴 함수에는 `private`을 사용할 수 없으므로 기본 `internal` 접근 수준을 사용한다.

## Child Feature와의 경계

Action 수가 많다는 이유만으로 Child Feature를 만들지 않는다. 가독성 문제는 역할별 reducer 함수·파일 분리로 해결한다.

State와 생명주기 소유권을 나누는 판단은 `feature-composition.md`를 따른다. 역할별 reducer는 **같은 State를 읽기 쉽게 다루는 가독성 경계**이고, Child Feature는 **State와 생명주기를 소유하는 설계 경계**다.

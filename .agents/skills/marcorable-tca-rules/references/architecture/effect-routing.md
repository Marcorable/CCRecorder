
# TCA Effect 흐름 연결

Effect 구현을 숨기는 `private func (...) -> Effect<Action>` factory는 만들지 않는다. 시작 조건과 결과 Action이 reducer의 흐름에 함께 보이게 구성한다.

## 한 번만 쓰는 짧은 Effect

한 Action에서만 시작하고 짧게 읽히는 Effect는 해당 case에 직접 작성한다.

```swift
case .view(.refreshButtonTapped):
    return .run { send in
        await send(.response(.itemsLoaded(
            TaskResult { try await catalogClient.items() }
        )))
    }
```

## 재사용하거나 독립된 Effect 흐름

여러 Action이 같은 Effect를 시작하거나 Effect 자체가 구분되는 흐름이면 시작을 `Response` case로 표현한다. 각 시작점은 같은 case를 보내고 실제 Effect는 response reducer 한 곳에서 실행한다.

```swift
case .view(.appeared):
    return .send(.response(.itemsLoading))

case .view(.queryChanged(let query)):
    state.query = query
    return .send(.response(.itemsLoading))

case .response(.itemsLoading):
    let query = state.query
    return .run { send in
        await send(.response(.itemsLoaded(
            TaskResult { try await catalogClient.items(query) }
        )))
    }

case .response(.itemsLoaded(.success(let items))):
    state.items = items
    return .none
```

- Effect 시작 case는 `itemsLoading`, 결과 case는 `itemsLoaded`처럼 흐름의 단계가 드러나는 사건으로 이름 짓는다
- Effect 실행 전용 `Request` 분류를 따로 만들지 않고 `Response` 흐름을 사용한다
- response reducer가 시작 Action을 받고 Effect가 결과 `Response`를 보내는 순환은 허용한다
- 순수 값 변환과 State 변경은 Effect 시작 case로 우회하지 않고 원래 Action에서 처리한다
- 역할별 `reduce(into:action:) -> Effect<Action>` 함수는 reducer 가독성 경계이므로 Effect factory로 보지 않는다

Effect의 취소와 장기 자원 수명은 `effect-lifecycle.md`, Action 역할 분류는 `action-organization.md`를 따른다.

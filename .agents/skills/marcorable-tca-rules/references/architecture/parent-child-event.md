
# TCA Parent에서 Child로 사건 전달

부모에서 발생한 사건을 Child가 자신의 State와 Effect 정책으로 해석해야 하면 Child의 `Parent` Action으로 전달한다.

```swift
enum Parent {
    case containerLoaded(Configuration)
    case containerDisappeared
}

case parent(Parent)
```

부모는 자신에게 도착한 사건을 Child Action으로 전달하고 구체적인 준비·정리 정책은 Child reducer가 결정한다.

```swift
case .response(.containerLoaded(let configuration)):
    return .send(.child(.parent(.containerLoaded(configuration))))
```

- `prepare`, `finish` 같은 메서드형 명령보다 `containerLoaded`, `containerDisappeared`처럼 부모에서 발생한 사건으로 이름 짓는다
- Child가 같은 Dependency와 Effect 생명주기를 소유해야 할 때 사용한다
- 부모가 Child의 Dependency 호출이나 응답을 대신 중계하지 않는다
- 순수 코드 재사용이나 reducer 내부 점프를 위해 `parent` Action으로 다시 진입하지 않는다
- Child에서 부모로 알릴 사건은 반대 방향인 `Delegate` Action을 사용한다

Action의 전체 역할 분류는 `action-organization.md`, Child의 소유권과 출력 경계는 `child-feature-communication.md`를 따른다.

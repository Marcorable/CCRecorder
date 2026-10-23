
# TCA Action 구성

Action은 발생 주체와 역할에 따라 묶어 의미와 탐색 경계를 드러낸다. Action 개수나 코드 줄 수로 기계적인 임계값을 정하지 않는다.

이 규칙은 reducer 함수·파일 분리와 독립적으로 적용한다. Action을 중첩했다고 reducer를 반드시 나눌 필요는 없고, reducer를 나누기 위해 Action을 반드시 중첩할 필요도 없다.

## TCA 연결 Action

TCA API와 직접 연결되는 Action은 해당 API의 형태를 유지한다.

- `child`: 하위 Feature의 Action
- `view`: `ViewAction`을 채택해 View에서 보낼 수 있는 행동을 제한할 때 사용
- `binding`: `BindableAction`과 `BindingReducer`를 사용할 때 추가
- `destination`: presentation state와 destination reducer를 조합할 때 추가

## marcorable 역할 Action

TCA API가 정하지 않은 내부 역할은 다음 이름을 기본값으로 사용한다. 필요한 종류만 만들고 빈 분류를 미리 만들지 않는다.

- `response`: API, 저장소, 타이머 같은 외부 작업의 응답
- `delegate`: 부모 Feature에 알릴 의미 있는 사건

```swift
enum Action: ViewAction {
    enum View {
        case appeared
        case queryChanged(String)
        case rowTapped(Row.ID)
    }

    enum Response {
        case rowsLoaded(TaskResult<[Row]>)
    }

    enum Delegate {
        case rowSelected(Row.ID)
    }

    case view(View)
    case response(Response)
    case child(ChildFeature.Action)
    case delegate(Delegate)
}
```

`view`, `binding`, `destination`, `child`는 TCA 조합 방식에 맞추고, `response`, `delegate`는 marcorable-tca가 선택한 역할 분류로 사용한다.

## 분류 기준

- Action의 이름은 구현 방법이 아니라 발생한 사건을 표현한다
- 모든 Action을 억지로 중첩하지 않는다. 한두 개뿐이고 역할이 명확하면 최상위에 둔다
- 어느 분류에도 자연스럽게 들어가지 않는 Action을 억지로 `response`에 넣지 않고 의미가 드러나는 최상위 case로 둔다
- TCA 연결 Action은 조합 API가 요구하는 형태를 유지한다
- 분류를 추가할 때는 기존 분류와 역할이 겹치지 않는지 먼저 확인한다

Action 분류 뒤 reducer 구현을 정리해야 하면 `reducer-decomposition.md`를 따른다.

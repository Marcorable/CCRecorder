
# TCA Feature State 선언 배치

이 규칙은 상태의 소유권이나 타입을 결정하지 않고, 이미 결정된 저장 프로퍼티와 `init`을 역할별로 배치한다. 상태 소유권은 `feature-state-ownership.md`, presentation 구성은 `presentation.md`를 따른다.

`State`는 생성과 실행 흐름이 위에서 아래로 읽히도록 다음 순서로 묶는다.

1. Feature 생성에 필요한 ID·입력값과 기본 상태
2. 함께 생성하거나 소유하는 Child Feature State
3. 명시적인 초기화가 필요할 때만 `init`
4. `@Presents` presentation 상태
5. Effect 실행 중 채워지거나 교체되는 데이터·진행 상태·결과

존재하는 묶음만 작성한다. 기본값이 있다는 이유만으로 실행 상태를 첫 묶음으로 옮기거나, 선언 순서를 맞추기 위해 불필요한 `init`을 만들지 않는다.

```swift
@ObservableState
struct State: Equatable {
    let itemID: Item.ID
    var mode: Mode = .summary

    var child: ChildFeature.State

    init(itemID: Item.ID) {
        self.itemID = itemID
        self.child = .init(itemID: itemID)
    }

    @Presents var alert: AlertState<Action.Alert>?
    @Presents var destination: Destination.State?

    var item: Item?
    var loadPhase: LoadPhase = .idle
}
```

같은 역할의 프로퍼티는 타입, `let`·`var`, Optional 여부보다 함께 생성되고 변경되는 흐름을 우선해 묶는다. 빈 줄은 프로퍼티 수가 아니라 역할과 생명주기 경계를 나타낸다. 자리를 유지하기 위한 빈 줄이나 구분 주석은 추가하지 않는다.

---
paths:
  - "**/*.swift"
---

# SwiftUI 표현 값과 파생 상태

표현 값을 계산 프로퍼티로 분리할지는 코드 길이가 아니라 상태 소유권, 프레임워크 의존성과 재사용 여부로 판단한다. 사용 위치에서 조건과 결과를 바로 이해할 수 있게 하는 것을 우선한다.

## 사용 위치에 직접 작성

다음 값은 별도 private 계산 프로퍼티를 만들지 않고 사용하는 View와 modifier에 직접 작성한다.

- 한 번만 사용하는 단독 삼항 연산
- Store Action 하나를 보내는 동작 클로저
- `Binding(get:set:)`처럼 특정 입력 View만 사용하는 바인딩
- 이름을 붙여도 표현 의도가 더 명확해지지 않는 단순 변환

```swift
Image(
    systemName: isVocabulary
        ? "textformat.abc"
        : "text.bubble.fill"
)

Button(
    action: { store.send(.view(.saveButtonTapped)) },
    label: {
        Text("저장")
    }
)
```

단지 `body`가 길어진다는 이유로 한 번만 사용하는 표현이나 클로저를 파일 아래의 private 프로퍼티·함수로 옮기지 않는다. 화면 구조를 가릴 정도의 독립된 UI 영역은 함수가 아니라 `view-composition.md`에 따라 중첩 View로 나눈다.

## View에 두는 값

다음 값은 Feature가 아니라 View 계층이 소유한다.

- `Color`, `Font`, `Image`, `LocalizedStringKey`, `ShapeStyle`, `PresentationDetent`처럼 SwiftUI가 필요한 표현
- 아이콘 이름, opacity처럼 화면에만 의미가 있는 최종 표시 값
- `@State`, `@FocusState`, `Environment` 값이 포함된 계산
- 같은 표현이 반복되거나 조건이 복잡해 이름이 읽기 흐름을 개선하는 값

View의 로컬 상태와 Store 상태를 함께 사용하면 `body`의 지역 값으로 계산해 사용하는 UI와 가까이 둔다.

```swift
var body: some View {
    let displayedTime = isEditing
        ? editingTime
        : store.currentTime

    Slider(
        value: .init(
            get: { displayedTime },
            set: { editingTime = $0 }
        ),
        in: .zero...store.duration
    )
}
```

중첩 삼항 연산은 사용 위치에 억지로 넣지 않는다. `switch`, 역할이 드러나는 private 계산 프로퍼티 또는 중첩 View를 사용한다.

## Feature.State에 두는 값

Feature 상태만으로 결정되고 SwiftUI 타입을 사용하지 않는 파생 상태는 `Feature.State`의 계산 프로퍼티로 표현할 수 있다.

- View의 여러 위치에서 같은 조건을 사용하는 경우
- View와 Effect가 같은 판단을 공유하는 경우
- 이름을 부여하면 상태 정책을 더 분명하게 읽을 수 있는 경우

```swift
@ObservableState
struct State: Equatable {
    var isPrepared = false

    var isPlaybackDisabled: Bool { !isPrepared }
}
```

Feature 상태를 단순히 다른 이름으로 한 번 감싸거나 `Color`, 아이콘 이름과 opacity 같은 표현 결정을 Feature에 넣지 않는다. `isRecordingIndicatorVisible`처럼 표현의 근거가 되는 프레임워크 중립 상태만 Feature에서 계산하고, opacity로 변환하는 일은 View에서 한다. Domain에도 화면 표시 문자열과 SwiftUI 표현 값을 두지 않는다.

## 표현 모델

공용 컴포넌트가 여러 Feature에서 사용되면 컴포넌트 전용 `Row.ViewModel`처럼 필요한 표시 데이터만 받는다. 원본 Domain Entity를 View에서 반복 해석하지 않는다.

- 여러 표시에서 공유하는 파생 값은 ViewModel에 둔다
- 한 번만 사용하는 단순 표현은 ViewModel 프로퍼티를 추가하지 않고 View 호출부에서 계산한다
- 복잡한 표시 선택은 역할이 드러나는 이름을 붙여 ViewModel이나 View private 계산으로 유지한다

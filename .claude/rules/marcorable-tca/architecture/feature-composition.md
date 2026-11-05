---
paths:
  - "**/*.swift"
---

# TCA 화면 Feature 구성

Feature 안에서만 쓰는 상태 구분 타입은 가장 가까운 State에 중첩한다. UI 타입과 Feature의 배치는 현재 UI 프레임워크에 맞춘다.

## SwiftUI

SwiftUI 화면은 `<Name>Screen` 네임스페이스 아래 `Root`와 `Root.Feature`로 구성한다.

```swift
enum SearchScreen {}

extension SearchScreen {

    struct Root: View {
        let store: StoreOf<Feature>
    }

}

extension SearchScreen.Root {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> { ... }
    }

}

extension SearchScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        var phase: Phase = .idle

        enum Phase: Equatable {
            case idle
            case loading
        }
    }

}
```

- 화면 전용 상태 구분 타입은 `State`에 중첩한다
- 화면 밖에서도 재사용하는 Entity·Usecase·Repository 타입은 Screen에 중첩하지 않는다
- State initializer가 저장 프로퍼티를 그대로 대입하기만 하면 프로퍼티 기본값과 합성 initializer를 사용한다

## UIKit

UIKit 화면은 프로젝트의 ViewController·Coordinator 배치를 유지하고 ViewController가 `StoreOf<Feature>`를 소유하거나 주입받는다. SwiftUI의 `Root` 타입을 만들지 않으며, Feature 이름과 위치는 기존 모듈의 관습을 따른다. State 내부 타입의 중첩 원칙은 SwiftUI와 같다.

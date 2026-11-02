---
paths:
  - "**/*.swift"
---

# TCA Feature 구성

화면은 `<Name>Screen` 네임스페이스 아래 `Root`와 `Root.Feature`로 구성한다. 화면 안에서만 쓰는 타입은 사용하는 State 또는 Feature에 중첩한다.

```swift
enum RecordScreen {}

extension RecordScreen {

    struct Root: View {
        let store: StoreOf<Feature>
    }

}

extension RecordScreen.Root {

    @Reducer
    struct Feature {
        var body: some ReducerOf<Self> { ... }
    }

}

extension RecordScreen.Root.Feature {

    @ObservableState
    struct State: Equatable {
        var phase: Phase = .idle

        enum Phase: Equatable {
            case idle
            case recording
        }
    }

    private enum CancelID {
        case recording
    }

}
```

- 화면 전용 상태 구분 타입은 `State`에 중첩한다
- Effect 취소 식별자는 사용하는 `Feature`에 `private`으로 중첩한다
- 화면 밖에서도 재사용하는 Entity·Usecase·Repository 타입은 Screen에 중첩하지 않는다
- State initializer가 저장 프로퍼티를 그대로 대입하기만 하면 프로퍼티 기본값과 합성 initializer를 사용한다

## Root Feature 책임

`<Name>Screen.Root.Feature`는 화면 전체를 조정하는 경계다. 모든 하위 업무를 직접 처리하는 단일 Feature로 만들지 않는다.

Root는 다음 책임을 소유한다.

- 화면을 구성하는 Child Feature의 State와 `Scope`
- sheet·fullScreenCover·alert 같은 presentation
- navigation과 화면 진입·종료
- 최초 데이터 조회와 그 결과에 따른 Child Feature 구성
- 둘 이상의 Child Feature가 함께 관여하는 상위 시나리오

하위 View에서 발생하는 주 업무는 해당 영역의 Child Feature가 소유한다. Child Feature는 부모 Store가 생성될 때 캡처한 Dependency를 상속하므로, Root가 Dependency 호출을 대신 전달하지 않는다.

- 재생 영역은 재생 State, 제어 Action, ticker Effect와 취소 범위를 소유한다
- 검색 영역은 검색어, 결과, 검색 Effect와 실패 상태를 소유한다
- 입력 영역은 입력값, 검증, 저장 Action과 응답을 소유한다

Root는 Child Feature의 의미 있는 완료·선택 같은 사건만 `delegate`로 받아 화면 전체 흐름에 반영한다. Child의 내부 Action과 Dependency 응답을 Root Action으로 중계하지 않는다.

Entity 하나를 Root와 여러 Child State에 복제해 동기화하지 않는다. 화면 전체에서 공유하는 Source of Truth가 필요하면 다음 순서로 경계를 정한다.

1. Entity의 실제 변경 업무를 소유하는 Feature 한 곳을 정한다.
2. 다른 Child에는 ID나 필요한 불변 입력만 전달한다.
3. 여러 Child가 항상 같은 Entity 전체를 변경해야 한다면 억지로 분리하지 않고 Root 소유를 유지한다.

## 하위 View와 Child Feature

하위 View가 부모 상태를 표시하고 부모 Action만 보낸다면 부모 Store를 전달한다. 중간 List가 있더라도 별도 상태와 생명주기가 없다면 Store 전달만 담당하고 Feature를 추가하지 않는다.

하위 View가 다음 책임 중 하나를 소유하면 Child Feature로 분리하고 `Scope`로 조합한다.

- 자체 State와 Action
- 독립적인 바인딩·검증
- 고유한 Effect 또는 취소 범위
- 독립 테스트 가치

```swift
Scope(
    state: \.conversationInfo,
    action: \.conversationInfo
) {
    ConversationInfoFeature()
}
```

Child Feature 분리는 View 계층의 깊이가 아니라 상태와 생명주기의 소유권으로 결정한다.

View 구조와 Feature 구조는 일치하지 않아도 된다. 여러 하위 View가 하나의 업무 상태를 함께 사용하면 동일한 Child Store를 각각 scope해 전달한다. 예를 들어 입력창과 목록이 모두 노트 업무에 속하면 서로 다른 View여도 하나의 `NotesFeature`가 소유할 수 있다.

## Navigation 컨테이너와 화면

Navigation 컨테이너와 루트 화면의 책임이 다르면 타입을 분리한다.

- 컨테이너는 path와 push·pop 정책을 소유한다
- 루트 화면은 탭, 목록, 화면 내부 presentation을 소유한다
- 컨테이너 이름을 화면 네임스페이스의 `Root`와 중복시키지 않는다

Navigation 전체를 TCA 상태 트리로 구성할지, 시스템 `NavigationStack`과 화면별 Store를 조합할지는 화면 간 상태 공유와 Dependency 수명 요구를 기준으로 정한다. 화면별 독립 Store를 선택하면 navigation 상태와 child reducer 자동 조합을 함께 포기한다는 점을 명시한다.

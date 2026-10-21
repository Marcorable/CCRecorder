
# 화면과 컴포넌트 배치

UI 코드는 **화면**과 **컴포넌트**로 나눠 폴더를 따로 둔다.

```
UserInterface/
├── Components/
│   └── NoteList/                       # 노트 탭과 대화 상세에서 함께 쓴다
│       ├── NoteList.swift
│       └── NoteList.Row.swift
└── Screens/
    ├── Screen.swift                    # 라우트
    ├── Main/
    │   ├── MainScreen.swift
    │   ├── MainScreen.Context.swift
    │   └── Subview/MainScreen.TabBar.swift
    ├── ConversationList/
    │   ├── ConversationListScreen.swift
    │   ├── ConversationListScreen.Context.swift
    │   └── Subview/ConversationListScreen.Conversations.swift   # 한 화면에서만 쓴다
    └── ConversationDetail/
```

## 화면

화면은 push, sheet, fullScreenCover, 탭 콘텐츠, 앱 루트처럼 **표시 단위로 띄워지는 View** 다.

- `<Name>Screen` 네임스페이스와 중첩 타입으로 만든다 (`agent-common/marcorable-swift/rules/architecture/screen-pattern.md`)
- `Screens/<Name>/` 에 화면마다 폴더 하나를 둔다
- **띄우는 쪽을 기준으로 폴더를 중첩하지 않는다.** 탭 안의 화면이나 모달로 뜨는 화면도 `Screens/` 바로 아래에 둔다. 띄우는 쪽이 바뀌어도 폴더는 그대로다

```
// ✅
Screens/Main/
Screens/Record/
Screens/NoteDetail/

// ❌ 누가 띄우는지로 중첩
Screens/Main/Record/
Screens/Main/Note/NoteDetail/
```

## 컴포넌트

컴포넌트는 **두 화면 이상에서 쓰고, 값과 클로저만 받는** View 다. 어떤 화면의 타입(`<Name>Screen` 의 중첩 타입, ViewModel, Intent)도 모른다.

- `Components/<Name>/` 에 둔다
- 컴포넌트의 부속 View 는 그 컴포넌트 안에 중첩한다 — `NoteList.Row`
- 사용자 동작은 클로저로 알린다. 화면 전환이나 데이터 저장은 컴포넌트가 하지 않고 화면이 한다

```swift
struct NoteList: View {
    let notes: [Note]
    let select: (Note) -> Void
    let onDelete: (IndexSet) -> Void
}
```

## 화면 전용 서브뷰

**다른 화면에서 함께 쓰지 않으면 무조건 그 화면의 중첩 서브뷰**다. 화면의 타입을 모르는 View 라도 한 화면에서만 쓰면 컴포넌트로 빼지 않는다.
두 번째 화면에서 쓰게 될 때 컴포넌트로 옮긴다.
`Screens/<Name>/Subview/` 에 `<Name>Screen.<Sub>` 로 둔다 (`agent-common/marcorable-swift/rules/architecture/section-subview.md`).

```swift
// MainScreen.Tab 을 알기 때문에 컴포넌트가 아니다
extension MainScreen {

    struct TabBar: View {
        @Binding var selectedTab: Tab
    }

}
```

중첩하지 않은 전역 서브뷰는 이름이 겹치기 쉽다. 같은 `PinButton` 이 화면 두 곳에 있으면 각 화면 아래에 중첩해 구분한다.

## 이름

- View 타입 이름에 `View` 접미사를 붙이지 않는다. 역할 이름 자체가 View 다 — `NoteList`, `TabBar`, `Row`
- 화면은 `<Name>Screen.Context` 로 쓴다. `<Name>View` 로 만들지 않는다

```swift
// ✅
NoteList(...)
NoteList.Row(...)
ConversationListScreen.Context()

// ❌
NoteListView(...)
NoteListRow(...)
ConversationListView()
```

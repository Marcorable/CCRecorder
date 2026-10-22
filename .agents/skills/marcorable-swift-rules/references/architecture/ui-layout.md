
# 화면과 컴포넌트 배치

UI 코드는 **화면**, **컴포넌트**, **공용 유틸리티**로 나눠 폴더를 따로 둔다.

아래 트리는 레이어 모듈이 없는 **단일 타깃 앱의 기본 구조**다. 레이어 모듈 앱은 `UserInterface/` 대신 Presentation 레이어의 소스 루트를 사용하되, 그 아래를 `Util/`, `Components/`, `Screens/`로 나누는 구조와 이 문서의 이름 규칙을 동일하게 적용한다 (`agent-common/marcorable-swift/rules/architecture/module-layout.md`).

기존 프로젝트를 수정할 때도 화면 폴더를 평평하게 두기, 한 화면 전용 타입을 중첩하기, `View` 접미사를 쓰지 않기 같은 원칙을 새 코드부터 적용한다. 기존 코드를 함께 이동하거나 이름을 바꿀지는 작업 범위에 포함된 경우에만 수행한다.

```
UserInterface/
├── Util/
│   ├── Feature/                        # 여러 UI 타입에 공통 기능을 부여하는 규약
│   │   └── IdentifiableFeature.swift
│   ├── Modifier/                       # View 에 기능을 더하는 modifier · 확장
│   │   └── TrailingActionFeature.swift
│   └── FormatStyle/                    # 여러 화면이 함께 쓰는 표시 포맷
│       └── PlaybackTimeFormatStyle.swift
├── Components/
│   └── NoteList/                       # 노트 탭과 대화 상세에서 함께 쓴다
│       ├── NoteList.swift
│       └── NoteList.Row.swift
└── Screens/
    ├── Screen.swift                    # 라우트
    ├── Main/
    │   ├── MainScreen.swift
    │   ├── MainScreen.Context.swift
    │   └── TabBar/
    │       └── MainScreen.TabBar.swift
    ├── ConversationList/
    │   ├── ConversationListScreen.swift
    │   ├── ConversationListScreen.Context.swift
    │   └── Board/                      # 한 화면에서만 쓴다
    │       ├── ConversationListScreen.Board.swift
    │       └── ConversationListScreen.Board.Row.swift
    └── ConversationDetail/
```

## 공용 UI 유틸리티

여러 화면에서 사용하는 modifier 와 `FormatStyle` 같은 표시 기반 타입은 `UserInterface/Util/<역할>/`에 둔다.

- `Util/` 바로 아래에는 파일을 두지 않는다. `Modifier/`, `FormatStyle/`처럼 역할이 드러나는 하위 폴더를 만든다
- `Feature/`에는 여러 UI 타입에 같은 기능을 부여하는 공용 프로토콜과 기본 구현을 둔다
- `Modifier/`에는 `ViewModifier`, View 기능 프로토콜과 관련 확장을 둔다
- `FormatStyle/`에는 여러 화면이 같은 형식으로 값을 표시할 때 쓰는 포맷 정책을 둔다
- `Utils/`, `Extension/`처럼 역할이 드러나지 않는 폴더에는 새 타입을 두지 않는다

값 전체가 식별자인 enum·불변 값 타입에는 프로젝트의 `IdentifiableFeature`(또는 같은 역할의 타입)를 쓴다. 이 팩이 프로토콜을 제공하지는 않는다. 그런 타입이 없으면 `Identifiable` 의 `id` 를 직접 구현한다. 특정 presentation에 한정하지 않으며 `sheet(item:)`, `fullScreenCover(item:)` 등 값으로 식별하는 UI 기능에 공통으로 쓴다. 값의 일부만 식별자이거나 변경 가능한 표시 값이 포함되면 직접 `id`를 구현한다.

```swift
protocol IdentifiableFeature: Hashable, Identifiable where ID == Self {}

extension IdentifiableFeature {

    var id: Self { self }

}

enum Sheet: IdentifiableFeature {
    case information
}
```

공용 프로토콜을 만들지 않는 프로젝트에서는 같은 의미를 표준 프로토콜로 직접 구현한다.

```swift
enum Sheet: Hashable, Identifiable {
    case information

    var id: Self { self }
}
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
`<Name>Screen.<Sub>` 로 중첩하고, 화면 폴더 아래 **서브뷰 이름의 폴더** `Screens/<Name>/<Sub>/` 에 둔다 (`agent-common/marcorable-swift/rules/architecture/section-subview.md`).

- `Subview/` 같은 중간 폴더를 두지 않는다. 화면 파일은 `<Name>Screen.swift`, `<Name>Screen.Context.swift` 처럼 파일명으로 구분되므로 서브뷰 폴더와 섞이지 않는다
- 파일이 하나뿐인 서브뷰도 폴더를 둔다
- 서브뷰에 중첩된 하위 View(`Board.Row`)와 값 타입(`PlaybackPanel.Speed`)은 그 서브뷰 폴더 안에 파일로 둔다. 폴더를 더 만들지 않는다

```
// ✅
Screens/ConversationDetail/
├── ConversationDetailScreen.swift
├── ConversationDetailScreen.Context.swift
└── PlaybackPanel/
    ├── ConversationDetailScreen.PlaybackPanel.swift
    ├── ConversationDetailScreen.PlaybackPanel.Speed.swift
    └── ConversationDetailScreen.PlaybackPanel.SpeedMenu.swift

// ❌
Screens/ConversationDetail/Subview/PlaybackPanel/Subview/ConversationDetailScreen.PlaybackPanel.SpeedMenu.swift
```

```swift
// MainScreen.Tab 을 알기 때문에 컴포넌트가 아니다
extension MainScreen {

    struct TabBar: View {
        @Binding var selectedTab: Tab
    }

}
```

View 가 아닌 타입도 같다. 재생 속도 `Speed` 를 재생 패널에서만 쓰면 `ConversationDetailScreen.PlaybackPanel.Speed` 로 중첩한다.
여러 화면이 함께 쓰는 값(사용자 설정값 등)만 화면 밖에 둔다 (`agent-common/marcorable-swift/rules/architecture/module-layout.md`).

중첩하지 않은 전역 서브뷰는 이름이 겹치기 쉽다. 같은 `PinButton` 이 화면 두 곳에 있으면 각 화면 아래에 중첩해 구분한다.

## 이름

- View 타입 이름에 `View` 접미사를 붙이지 않는다. 역할 이름 자체가 View 다 — `NoteList`, `TabBar`, `Row`
- 화면은 `<Name>Screen.Context` 로 쓴다. `<Name>View` 로 만들지 않는다
- 목록과 빈 상태(`ContentUnavailableView`)를 함께 보여주는 묶음은 `Board` 로 짓는다 — `ConversationListScreen.Board`. 내용물 이름(`Conversations`)으로 짓지 않는다
- 녹음·재생처럼 미디어 상태를 조작하는 고정 영역은 `Panel` 로 짓는다 — `RecordScreen.RecordingPanel`, `ConversationDetailScreen.PlaybackPanel`. `Board`·`Tab` 과 섞지 않는다

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

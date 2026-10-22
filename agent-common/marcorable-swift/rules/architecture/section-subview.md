---
paths:
  - "**/*.swift"
---

# 섹션 서브뷰 구성

화면을 이루는 큰 영역(섹션, 보드, 패널)과 반복 표시 단위(Row)는 **부모 화면 타입 안에 중첩**한다.
외부 데이터를 입력받는 구조적 하위 View 는 필드가 하나여도 자기 `Model` 과 `ViewModel` 을 함께 가진다.
입력 데이터가 없는 정적 View 에는 빈 타입을 만들지 않는다.

## 파일과 이름

- 파일명: `<부모>.<섹션>.swift` — 예) `MartInfoScreen.BusinessInfoSection.swift`, `BarcodeRegisterScreen.Board.swift`
- 위치: 부모 화면 폴더 아래 섹션 이름의 폴더 — `MartInfo/BusinessInfoSection/`. `Subview/` 폴더는 두지 않는다 (`agent-common/marcorable-swift/rules/architecture/ui-layout.md`)
- 선언: `extension <부모> { struct <섹션>: View { ... } }`

## 역할과 데이터 흐름

```text
원본 데이터 → 하위 View.Model → 하위 View.ViewModel → 하위 View
                   ↑
         Screen.ViewModel 이 조립
```

- `Model` 은 원본에서 받은 값을 변형하지 않고 보관하는 불변 `struct` 다. Optional 과 원본 값 타입도 그대로 유지한다
- `ViewModel` 은 `Model` 을 소유하고 View 가 바로 사용할 포맷, 기본값, 파생 상태를 연산 프로퍼티나 메서드로 제공한다
- 하위 ViewModel 은 기본적으로 불변 `struct` 다. 하위 View 가 독립적인 변경 상태를 소유할 때만 `@MainActor @Observable final class` 로 만든다
- View 는 ViewModel 을 입력받아 선언적으로 배치한다. 원본 Model 을 직접 해석하거나 Optional 기본값을 결정하지 않는다
- 값 타입 하위 ViewModel 은 `Screen.ViewModel` 의 연산 프로퍼티로 조립한다
- 상태를 가진 참조 타입 하위 ViewModel 은 `Screen.ViewModel` 의 저장 프로퍼티로 한 번 생성한다. 연산 프로퍼티에서 새 인스턴스를 반환하지 않는다
- `Context` 는 부모가 제공한 하위 ViewModel 을 하위 View 에 연결한다

## 한 파일 안의 구성 순서

```swift
extension SettingScreen {

    struct InformationSection: View {
        let viewModel: ViewModel

        var body: some View {
            Section("앱 정보") {
                LabeledContent("버전", value: viewModel.appVersion)
            }
        }
    }

}

extension SettingScreen.InformationSection {

    struct Model {
        let appVersion: String?
    }

    struct ViewModel {
        let model: Model
    }

}

extension SettingScreen.InformationSection.ViewModel {

    var appVersion: String {
        model.appVersion ?? "알 수 없음"
    }

}

#Preview {
    SettingScreen.InformationSection(
        viewModel: .init(
            model: .init(appVersion: "1.0")
        )
    )
}
```

Screen ViewModel 은 원본을 하위 View 의 입력으로 변환한다.

```swift
extension SettingScreen.ViewModel {

    var informationSection: SettingScreen.InformationSection.ViewModel {
        .init(
            model: .init(appVersion: model.appVersion)
        )
    }

}
```

하위 ViewModel 이 독립적인 변경 상태를 가지면 부모가 인스턴스를 저장한다.

```swift
extension ConversationDetailScreen {

    @MainActor
    @Observable
    final class ViewModel {
        let playbackPanel: PlaybackPanel.ViewModel

        private let model: Model

        init(model: Model) {
            self.model = model
            self.playbackPanel = .init(model: model.playbackPanel)
        }
    }

}
```

## 표시와 동작의 경계

- 데이터 값에 따라 바뀌는 포맷, Optional 기본값, 파생 상태와 액션 결과는 ViewModel 에 둔다
- `"앱 정보"`, `"버전"`처럼 데이터나 액션과 무관한 고정 문구와 컴포넌트 구성은 View 에 둔다
- `@Binding`, 동작 클로저, 환경 의존성은 원본 데이터가 아니므로 Model 에 넣지 않는다
- 화면 전용 하위 View 가 화면 단위 상태를 읽거나 Intent 를 보낼 때는 `@Environment(<Screen>.ViewModel.self)`를 사용한다. 하위 View 자신의 표시 데이터까지 Screen ViewModel 에서 직접 찾지 않고 자기 ViewModel 로 받는다
- 두 화면 이상에서 같은 View 가 쓰이면 공용 컴포넌트로 뺀다. 컴포넌트는 특정 Screen ViewModel 을 몰라야 하므로 값과 클로저만 받는다 (`agent-common/marcorable-swift/rules/architecture/ui-layout.md`)

## 원칙

- 원본 Entity 를 Model 로 그대로 노출하지 않는다. 하위 View 에 필요한 필드만 복사한다
- 데이터가 있는 구조적 하위 View(`Section`, `Row`, `Board`, `Panel`)는 간단해도 Model 과 ViewModel 을 생략하지 않는다
- 단순 전달 연산 프로퍼티가 생기더라도 일관된 변환 경계를 위한 비용으로 허용한다
- 섹션 하나에 `#Preview` 하나를 두고, 실제와 비슷한 샘플 값을 넣는다

## View 나누기

View 를 나눌 때는 **중첩 View 타입**을 만든다. `func` 나 `@ViewBuilder var` 로 나누지 않는다.
데이터를 입력받는 구조적 하위 View 는 위 Model/ViewModel 경계를 따르고, 데이터가 없는 장식용 View 는 필요한 UI 의존성만 프로퍼티로 받는다.

```swift
// ✅
extension OrderRow {

    struct PriceLabel: View {
        let price: Int

        var body: some View { ... }
    }

}

// ❌
private func priceLabel() -> some View { ... }
@ViewBuilder private var priceLabel: some View { ... }
```

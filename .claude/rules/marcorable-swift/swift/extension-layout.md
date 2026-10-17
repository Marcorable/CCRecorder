---
paths:
  - "**/*.swift"
---

# 타입 구성과 extension 분리

타입 본체에는 **저장 프로퍼티와 init, 바인딩**만 두고 나머지는 역할별 extension 으로 나눈다.

## 순서

1. 타입 본체 — 저장 프로퍼티, `init`, `bind()`
2. `Dependency`, 입력/출력 enum 같은 중첩 타입
3. `action` 진입점
4. private 헬퍼
5. `#if DEBUG` 로 감싼 `static var mock`

중첩 타입·`action`·헬퍼·`mock` 은 각각 **별도 extension** 으로 둔다. 구분은 extension 으로 하고 `// MARK:` 주석은 달지 않는다.

## 공백

**extension 만 빈 줄로 열고 닫는다.** 타입 본문은 빈 줄 없이 바로 시작하고 바로 닫는다.

- `extension X {` 다음 줄과 닫는 `}` 앞 줄은 **빈 줄**로 둔다
- `class`, `struct`, `enum`, `protocol` 본문은 여는 `{` 다음 줄에 바로 첫 멤버를 쓰고, 마지막 멤버 다음 줄에 바로 `}` 를 닫는다
- 본문 안에서는 성격이 다른 멤버 묶음 사이에만 빈 줄을 둔다 (저장 프로퍼티 묶음과 `init` 사이 등)

```swift
// ✅
extension SearchScreen {

    @MainActor
    @Observable
    final class ViewModel {
        private(set) var input = ""
        private let model: Model

        init(model: Model) {
            self.model = model
        }
    }

}

// ❌ 타입 본문을 빈 줄로 열고 닫음
extension SearchScreen {

    final class ViewModel {

        private(set) var input = ""

    }

}

// ❌ extension 을 빈 줄 없이 열고 닫음
extension SearchScreen {
    final class ViewModel {
        ...
    }
}
```

## 중첩 타입

화면에 딸린 타입은 전역에 두지 않고 화면 타입 안에 중첩한다.
`MartInfoView.BusinessInfoSection`, `BarcodeRegisterScreen.Model` 처럼 쓴다.
긴 중첩 이름은 `typealias` 로 줄인다.

```swift
typealias SalesInfoViewModel = MartInfoView.SalesInfoSection.ViewModel
```

## 확장 파일 이름

기존 타입을 확장하는 파일은 `<타입> + <기능>.swift` 로 짓는다. 함수를 더하면 이름 뒤에 `()` 를 붙인다.

```
String + maskedPhoneNumber.swift        // 프로퍼티
View + toolTip().swift                  // 함수
PresentationFactory + screen().swift
```

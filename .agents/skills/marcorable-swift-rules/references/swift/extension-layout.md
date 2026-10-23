
# 타입 구성과 extension 분리

타입 본체에는 **저장 프로퍼티와 init, 바인딩**만 두고 나머지는 역할별 extension 으로 나눈다.

## 순서

1. 타입 본체 — 저장 프로퍼티, `init`, `bind()`
2. `Dependency`, `Configuration`, 입력/출력 enum 같은 중첩 타입
3. 공개 동작 진입점
4. private 헬퍼
5. `#if DEBUG` 로 감싼 `static var mock`

중첩 타입·공개 동작·헬퍼·`mock`은 각각 **별도 extension**으로 둔다. 구분은 extension으로 하고 `// MARK:` 주석은 달지 않는다. 한 선언 안에서 case를 용도별로 묶을 때만 `// MARK:`를 쓴다.

## 공백

**extension 만 빈 줄로 열고 닫는다.** 타입 본문은 빈 줄 없이 바로 시작하고 바로 닫는다.

- `extension X {` 다음 줄과 닫는 `}` 앞 줄은 **빈 줄**로 둔다
- `class`, `struct`, `enum`, `protocol` 본문은 여는 `{` 다음 줄에 바로 첫 멤버를 쓰고, 마지막 멤버 다음 줄에 바로 `}` 를 닫는다
- 본문 안에서는 성격이 다른 멤버 묶음 사이에만 빈 줄을 둔다 (저장 프로퍼티 묶음과 `init` 사이 등)

```swift
// ✅
extension SearchService {

    struct Configuration {
        let minimumQueryLength: Int

        init(minimumQueryLength: Int) {
            self.minimumQueryLength = minimumQueryLength
        }
    }

}

// ❌ 타입 본문을 빈 줄로 열고 닫음
extension SearchService {

    struct Configuration {

        let minimumQueryLength: Int

    }

}

// ❌ extension 을 빈 줄 없이 열고 닫음
extension SearchService {
    struct Configuration {
        ...
    }
}
```

## 중첩 타입

특정 소유자에게만 딸린 타입은 전역에 두지 않고 그 타입 안에 중첩한다.
`SearchService.Configuration`, `ConversationScreen.Filter`처럼 쓴다.
긴 중첩 이름은 `typealias` 로 줄인다.

```swift
typealias ConversationFilter = ConversationScreen.Filter
```

## 확장 파일 이름

기존 타입을 확장하는 파일은 `<타입> + <기능>.swift` 로 짓는다. 함수를 더하면 이름 뒤에 `()` 를 붙인다.

```
String + maskedPhoneNumber.swift        // 프로퍼티
View + toolTip().swift                  // 함수
PresentationFactory + screen().swift
```

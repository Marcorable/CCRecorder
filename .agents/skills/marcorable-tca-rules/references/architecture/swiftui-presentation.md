
# TCA SwiftUI presentation 연결

이 규칙은 SwiftUI 화면에만 적용한다. `presentation.md`의 `@Presents` 상태를 scoped Store로 바꾸어 시스템 presentation API에 연결한다.

```swift
.sheet(
    item: $store.scope(
        state: \.detail,
        action: \.detail
    )
) { store in
    DetailScreen.Root(store: store)
}
```

- Entity Optional이나 Bool을 별도로 두고 수동 Binding으로 dismiss를 흉내 내지 않는다
- View는 presentation 표시만 담당하고 생성·dismiss 후처리 정책은 Feature에 둔다
- `marcorable-swiftui` 팩이 설치되어 있으면 해당 팩의 presentation 규칙도 함께 따른다

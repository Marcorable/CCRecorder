
# TCA Preview

Preview는 확인하려는 State를 `Store`의 `initialState`로 만들고 Mock 또는 preview Dependency를 주입한다.
Store 생성 문법은 `store-initialization.md`를 따른다.

```swift
#Preview {
    RecordScreen.Root(
        store: .init(
            initialState: .init(),
            reducer: { RecordScreen.Root.Feature() },
            withDependencies: {
                $0.recordUsecase = .live(service: MockRecorderService())
                $0.saveConversationUsecase = .live(
                    repository: ConversationRepositoryConcrete(modelContext: .mock),
                    fileStore: RecordFileStore()
                )
            }
        )
    )
}
```

- State는 Preview 때문에 실행 중 setter를 열지 않고 생성 시점에 완성한다
- 상태별 Preview는 해당 상태를 명시적으로 초기화한다
- 실제 Service·Repository 대신 Mock 또는 `previewValue`를 사용한다
- `previewValue`는 Preview가 실행하는 모든 endpoint가 구현되어 있을 때만 사용한다

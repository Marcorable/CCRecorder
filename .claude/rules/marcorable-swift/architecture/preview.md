---
paths:
  - "**/*.swift"
---

# 프리뷰

모든 화면과 섹션은 프리뷰로 바로 확인할 수 있어야 한다.

## 화면 단위

ViewModel/Model 에 `#if DEBUG` 로 감싼 `static var mock` 을 두고, 의존성은 `Mock*` 구현으로 채운다. 같은 `mock` 을 테스트에도 쓴다.

```swift
#if DEBUG
extension MartInfoViewModel {

    static var mock: Self {
        .init(
            dependency: .init(
                mainUsecase: MockManagingMartInfoUsecase(),
                loginUsecase: MockManagingLoginUsecase(),
                channelTalkService: MockChannelTalkService()
            )
        )
    }

}
#endif
```

필요한 `Mock*` 이 없으면 만든다. 프리뷰를 위해 실제 Usecase 를 주입하지 않는다.
`Mock*` 은 테스트와 같이 쓴다. 만드는 방법은 `.claude/rules/marcorable-swift/swift/testing.md` 의 "Mock" 을 따른다.

## 컨테이너

툴팁처럼 상위 컨테이너가 있어야 동작하는 컴포넌트를 쓰는 화면은 프리뷰에서도 그 컨테이너로 감싼다.

```swift
#Preview {
    TooltipContainerView {
        MartInfoView(viewModel: .mock)
    }
}
```

## 섹션 단위

배경이 흰색인 섹션은 경계가 보이도록 어두운 배경 위에 올린다.

```swift
#Preview {
    Color.black.overlay {
        MartInfoView.BusinessInfoSection(viewModel: .init(model: .init(...)))
            .background(.white)
    }
}
```

## 상태별 확인

데이터를 불러오기 전(`model == nil`) 상태도 프리뷰에서 깨지지 않아야 한다. 빈 문자열이나 플레이스홀더가 보여야 한다.

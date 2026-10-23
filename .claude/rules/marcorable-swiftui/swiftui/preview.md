---
paths:
  - "**/*.swift"
---

# 프리뷰

모든 화면과 섹션은 프리뷰로 바로 확인할 수 있어야 한다.

## 화면 단위

선택한 아키텍처 팩의 Preview 진입점을 사용해 화면 상태와 의존성을 명시한다. Preview를 위해 실제 서버, 저장소나 운영 계정을 사용하지 않는다. 정적 View는 필요한 값만 직접 전달한다.

## 컨테이너

툴팁처럼 상위 컨테이너가 있어야 동작하는 컴포넌트를 쓰는 화면은 프리뷰에서도 그 컨테이너로 감싼다.

```swift
#Preview {
    TooltipContainerView {
        SampleScreen.Root(/* Preview 상태 */)
    }
}
```

## 섹션 단위

배경이 흰색인 섹션은 경계가 보이도록 어두운 배경 위에 올린다.

```swift
#Preview {
    Color.black.overlay {
        SampleScreen.InformationSection(/* 실제와 비슷한 샘플 값 */)
            .background(.white)
    }
}
```

## 상태별 확인

불러오기 전, 값 없음, 결과 없음, 오류와 로딩 상태도 프리뷰에서 깨지지 않아야 한다. 상태의 의미는 `agent-common/marcorable-swiftui/rules/application/screen-state.md`를 따르고, 표시 기본값을 만드는 위치는 선택한 아키텍처가 정한다.

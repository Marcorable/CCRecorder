---
paths:
  - "**/*.swift"
---

# TCA Effect 취소 식별자

Effect 취소 식별자는 그 Effect를 소유한 Feature 안에 `CancelID`로 중첩한다.

```swift
extension SearchFeature {

    private enum CancelID {
        case loading
        case updates
    }

}
```

- 같은 파일에서만 사용하면 `private`으로 둔다
- 역할별 reducer를 다른 파일로 분리해 공유해야 하면 Feature 중첩은 유지하고 기본 `internal` 접근 수준을 사용한다
- case는 시작 버튼이나 화면 이름보다 취소할 작업의 정체성이 드러나게 짓는다
- 문자열이나 다른 Feature의 취소 식별자를 재사용하지 않는다

취소 시점과 자원 정리 정책은 `effect-lifecycle.md`, Feature 파일 분리는 `feature-file-layout.md`를 따른다.

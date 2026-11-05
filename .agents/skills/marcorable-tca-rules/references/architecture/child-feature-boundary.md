
# TCA Child Feature 경계

Child Feature는 View 계층을 닮게 만드는 단위가 아니라 상태와 Effect 생명주기의 소유권을 나누는 단위다.

하위 View가 부모 상태를 표시하고 부모 Action만 보낸다면 부모 Store를 전달한다. 자체 State와 Action을 가지면서 다음 중 하나 이상의 정책이나 수명을 독립적으로 소유할 때 Child Feature로 분리한다.

- 독립적인 바인딩 또는 검증
- 고유한 Effect 또는 취소 범위
- 독립 테스트 가치

Action 수, 파일 길이와 View 계층의 깊이만으로는 Child Feature를 만들지 않는다. 여러 View가 같은 업무 상태를 사용하면 하나의 Child Store를 각각 scope해 전달한다.

```swift
Scope(
    state: \.search,
    action: \.search
) {
    SearchFeature()
}
```

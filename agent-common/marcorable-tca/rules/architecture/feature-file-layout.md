---
paths:
  - "**/*.swift"
---

# TCA Feature 파일 배치

한 파일에서는 Feature의 의존성과 전체 Action 흐름을 먼저 읽고 세부 구현으로 내려갈 수 있게 배치한다.

1. `@Reducer Feature` 본체에 `@Dependency`와 `body`를 둔다
2. 첫 번째 `Feature` extension에 `State`, `Action`, `CancelID`를 둔다
3. 다음 `Feature` extension부터 역할별 reducer 구현을 둔다

`State`와 `Action`이 길어져도 최상위 Action routing은 `body`에 남긴다. 전체 `Action`을 받는 `route`, `coreReduce`, `reduce(into:action: Action)` 같은 중간 함수나 별도 routing 파일은 만들지 않는다.

역할별 reducer가 길어지면 다음처럼 역할 타입 단위로 파일을 나눈다.

```text
SearchFeature/
├── SearchFeature.swift
├── SearchFeature + ViewReducer.swift
└── SearchFeature + ResponseReducer.swift
```

다른 파일의 extension으로 옮긴 역할별 reducer는 기본 `internal` 접근 수준을 사용한다. 구체적인 분리 기준과 함수 형태는 `reducer-decomposition.md`, 취소 식별자의 접근 수준은 `cancellation-identity.md`를 따른다.

`State` 내부의 역할별 프로퍼티와 `init` 선언 순서는 `feature-state-layout.md`를 따른다.

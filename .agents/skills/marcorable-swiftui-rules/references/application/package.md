
# 로컬 SPM 패키지

타깃이 하나뿐이면 기본 폴더(`Sources/<타깃명>/`) 대신 `path:` 로 `Sources/`, `Tests/` 를 바로 쓴다. 폴더를 한 단계 줄인다.

```swift
.target(
    name: "SharedKit",
    path: "Sources"
),
.testTarget(
    name: "SharedKitTests",
    dependencies: ["SharedKit"],
    path: "Tests"
)
```

```
SharedKit/
├── Package.swift
├── Sources/        ← Sources/SharedKit/ 가 아니다
└── Tests/
```
